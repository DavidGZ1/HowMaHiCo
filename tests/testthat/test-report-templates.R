# v0.28.0: the focused reports no longer pull their setup in through a knitr
# child (RStudio's "Run All" skips child chunks, so the report could not be
# stepped through outside a knit). They call report_setup(params) from an
# ordinary chunk instead. Guard both halves, and that no template still points
# at the removed shared setup.Rmd.

test_that("focused templates set up through report_setup(), not a child", {
  dir_templates <- system.file("rmarkdown", "templates", package = "HowMaHiCo")
  skip_if(dir_templates == "", "report templates not installed")
  expect_equal(system.file("rmarkdown", "shared", "setup.Rmd", package = "HowMaHiCo"),
               "")
  for (tpl in c("01_mhc_overview", "02_prot_all", "03_lcms_qc", "04_pepchem",
                "05_quant_stats")) {
    lines <- readLines(file.path(dir_templates, tpl, "skeleton", "skeleton.Rmd"),
                       warn = FALSE)
    expect_false(any(grepl("setup.Rmd", lines, fixed = TRUE)), info = tpl)
    expect_equal(sum(startsWith(lines, "report_setup(params)")), 1L, info = tpl)
    # exactly one 'setup'-labelled chunk (knitr's chunk-begin pattern)
    expect_equal(sum(grepl("^[\t >]*```+\\s*\\{[rR][ ,]*setup[ ,}]", lines)), 1L,
                 info = tpl)
  }
})

# Registration guard: run_howmahico_report() dispatches through match.arg(), so a
# template shipped in inst/rmarkdown/templates but missing from its `template`
# choices is unreachable (this is how the old 05_quality_score slipped through v0.10.0).

test_that("every shipped report template is offered by run_howmahico_report()", {
  dir_templates <- system.file("rmarkdown", "templates", package = "HowMaHiCo")
  skip_if(dir_templates == "", "report templates not installed")

  shipped <- list.dirs(dir_templates, full.names = FALSE, recursive = FALSE)
  shipped <- shipped[nzchar(shipped)]
  offered <- eval(formals(run_howmahico_report)$template)

  expect_setequal(shipped, offered)
  # and each of them really has a skeleton to render
  for (tpl in shipped)
    expect_true(file.exists(file.path(dir_templates, tpl, "skeleton", "skeleton.Rmd")))
  # the template.yaml name matches its directory (RStudio's template picker)
  for (tpl in shipped) {
    yml <- yaml::read_yaml(file.path(dir_templates, tpl, "template.yaml"))
    expect_equal(yml$name, tpl, info = tpl)
  }
})

# Renaming guard (v0.27.0): 01/02/04/05/09 were merged into 01_mhc_overview and
# 06/07/08 renumbered. The old names keep working through an alias table, so
# existing user scripts and the demo do not break; every alias must point at a
# template that really ships, and every old name must be covered.
test_that("pre-v0.27.0 template names resolve to a shipped report, with a warning", {
  offered <- eval(formals(run_howmahico_report)$template)
  aliases <- HowMaHiCo:::.template_aliases

  expect_setequal(names(aliases),
                  c("01_id_counts", "02_overlaps", "04_quant", "05_quality_score",
                    "09_overview", "06_quant_stats", "07_pepchem", "08_prot_all"))
  expect_true(all(aliases %in% offered))
  expect_false(any(names(aliases) %in% offered))

  for (old in names(aliases))
    expect_warning(res <- HowMaHiCo:::.resolve_template_alias(old), "renamed in HowMaHiCo 0.27.0")
  expect_equal(HowMaHiCo:::.resolve_template_alias("07_pepchem") |> suppressWarnings(),
               "04_pepchem")
  # current names and the default choice vector pass through silently
  expect_silent(expect_equal(HowMaHiCo:::.resolve_template_alias("03_lcms_qc"), "03_lcms_qc"))
  expect_silent(HowMaHiCo:::.resolve_template_alias(offered))
})

# Param-consistency guard (v0.17.0): the templates share a common param block, but
# it is maintained by hand in nine separate YAML headers, so a param added to a
# new report is easy to forget in the older ones. A missing param is not a soft
# failure -- rmarkdown::render() stops with "render params not declared in YAML"
# when a caller passes one the template does not declare, so a single omission
# breaks that report for every script that sets the param.

common_params <- c("SampleSet", "Provider", "DataAnalysisNames",
                   "FolderDocumentation", "AnnotationFile", "Subset",
                   "FolderData", "FolderResults", "FolderFigures", "ProjectDir",
                   "Instrument", "Software", "MHCclass",
                   "ShortPeptideLengthMin", "ShortPeptideLengthMax",
                   "TestMode", "ResultsOverwrite", "PlotsSave", "CsvSave",
                   "InteractivePlots")

template_params <- function(dir_templates, tpl) {
  rmd <- file.path(dir_templates, tpl, "skeleton", "skeleton.Rmd")
  names(knitr::knit_params(readLines(rmd, warn = FALSE)))
}

test_that("every shipped template declares the common report params", {
  dir_templates <- system.file("rmarkdown", "templates", package = "HowMaHiCo")
  skip_if(dir_templates == "", "report templates not installed")
  skip_if_not_installed("knitr")

  shipped <- list.dirs(dir_templates, full.names = FALSE, recursive = FALSE)
  shipped <- shipped[nzchar(shipped)]

  for (tpl in shipped) {
    missing <- setdiff(common_params, template_params(dir_templates, tpl))
    expect_equal(missing, character(0),
                 info = paste0("Template '", tpl, "' does not declare: ",
                               paste(missing, collapse = ", ")))
  }
})

test_that("no shipped template hardcodes a provider or author into its header", {
  dir_templates <- system.file("rmarkdown", "templates", package = "HowMaHiCo")
  skip_if(dir_templates == "", "report templates not installed")

  shipped <- list.dirs(dir_templates, full.names = FALSE, recursive = FALSE)
  shipped <- shipped[nzchar(shipped)]

  for (tpl in shipped) {
    rmd <- file.path(dir_templates, tpl, "skeleton", "skeleton.Rmd")
    lines <- readLines(rmd, warn = FALSE)

    branded <- grep("Immunopeptidomics Platform|Code author|dkfz", lines,
                    value = TRUE, ignore.case = TRUE)
    expect_equal(branded, character(0),
                 info = paste0("Template '", tpl, "' hardcodes an organisation, ",
                               "author or contact address: ",
                               paste(branded, collapse = " | ")))

    # ... and every template renders the attribution from the param instead
    expect_true(any(grepl("provider_line(params$Provider)", lines, fixed = TRUE)),
                info = paste0("Template '", tpl, "' never calls provider_line()."))
  }
})

# Interactivity boundary (v0.21.0): ggprint_rawr(interactive = TRUE) returns a
# plotly htmlwidget, and a widget printed from inside a results='asis' loop needs
# an explicit tagList/knit_print dance to get its dependencies attached -- without
# it the tab renders EMPTY, with no error. So the toggle is wired only into
# ordinary chunks, and this guards that boundary.

test_that("no results='asis' chunk prints an interactive plot", {
  dir_templates <- system.file("rmarkdown", "templates", package = "HowMaHiCo")
  skip_if(dir_templates == "", "report templates not installed")

  shipped <- list.dirs(dir_templates, full.names = FALSE, recursive = FALSE)
  shipped <- shipped[nzchar(shipped)]

  chunk_begin <- "^[\t >]*```+\\s*\\{[rR][ ,}]"
  chunk_end   <- "^[\t >]*```+\\s*$"

  for (tpl in shipped) {
    lines <- readLines(file.path(dir_templates, tpl, "skeleton", "skeleton.Rmd"),
                       warn = FALSE)
    in_chunk <- FALSE; asis <- FALSE; offenders <- character(0)
    for (ln in lines) {
      if (!in_chunk && grepl(chunk_begin, ln)) {
        in_chunk <- TRUE; asis <- grepl("asis", ln, fixed = TRUE); next
      }
      if (in_chunk && grepl(chunk_end, ln)) { in_chunk <- FALSE; next }
      if (in_chunk && asis && grepl("interactive = ", ln, fixed = TRUE))
        offenders <- c(offenders, trimws(ln))
    }
    expect_equal(offenders, character(0),
                 info = paste0("Template '", tpl, "' asks for an interactive plot ",
                               "inside a results='asis' chunk: ",
                               paste(offenders, collapse = " | ")))
  }
})

test_that("every template that prints plots derives interactive_plots from the param", {
  dir_templates <- system.file("rmarkdown", "templates", package = "HowMaHiCo")
  skip_if(dir_templates == "", "report templates not installed")
  # report_setup() derives interactive_plots for the focused templates

  shipped <- list.dirs(dir_templates, full.names = FALSE, recursive = FALSE)
  shipped <- shipped[nzchar(shipped)]

  for (tpl in shipped) {
    lines <- readLines(file.path(dir_templates, tpl, "skeleton", "skeleton.Rmd"),
                       warn = FALSE)
    uses <- any(grepl("interactive = interactive_plots", lines, fixed = TRUE))
    if (!uses) next
    # either the template derives it itself (the two 00_* reports) or it calls
    # report_setup(), which does
    derives <- any(grepl("interactive_plots <- isTRUE(params$InteractivePlots)",
                         lines, fixed = TRUE)) ||
      (any(startsWith(lines, "report_setup(params)")) &&
         any(grepl("interactive_plots <- isTRUE(p$InteractivePlots)",
                   deparse(report_setup), fixed = TRUE)))
    expect_true(derives,
                info = paste0("Template '", tpl, "' uses interactive_plots but ",
                              "never derives it."))
  }
})
