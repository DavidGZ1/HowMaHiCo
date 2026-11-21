# Tests against the simulated FragPipe dataset shipped in inst/extdata
# (sim_fragpipe_dda: 2 Conditions x 3 BioReplicates, individual-mode psm.tsv;
# generated with MaHiCoInSilico). Unlike the hand-synthesized loader fixtures,
# this is a realistically sized, multi-condition dataset, so it exercises the full
# build -> render path (correlation, %CV, UpSet, combn(conditions, 2) all valid).

sim_dir   <- system.file("extdata", "sim_fragpipe_dda", package = "HowMaHiCo")
sim_annot <- system.file("extdata", "sim_fragpipe_dda_annotation.csv", package = "HowMaHiCo")

test_that("build_pep_all on the simulated FragPipe data yields a valid 2-condition pep_all", {
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  annot <- read_annot(sim_annot)
  pep_all <- suppressWarnings(suppressMessages(
    build_pep_all("fragpipe_dda_individual", folder_data = sim_dir,
                  annotation = annot, shortpep_range = c(8, 13))))

  expect_silent(validate_pep_all(pep_all, "FragPipe"))
  expect_setequal(levels(pep_all$Condition), c("CTRL", "TREAT"))
  expect_equal(dplyr::n_distinct(pep_all$Sample), 6L)
  expect_gt(nrow(pep_all), 0)
})

# The main report, 01_mhc_overview (v0.27.0), merges what used to be 01_id_counts,
# 02_overlaps, 04_quant, 05_quality_score and 09_overview, so this one render
# carries all of their former assertions. Render guard (v0.16.0): the old
# 05_quality_score had an inline `r ...` expression that was a syntax error and
# had never rendered, because no test covered it. Inline expressions are only
# parsed at render time, so every shipped template needs a render test.
test_that("01_mhc_overview renders end-to-end against the simulated data (PepAllSource = build)", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  # Copy the read-only extdata into a writable temp project so the build-mode
  # cache write (and outputs) land somewhere writable.
  proj <- tempfile("simproj_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)            # proj/sim_fragpipe_dda/<samples>
  file.copy(sim_annot, proj)                            # proj/sim_fragpipe_dda_annotation.csv

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "01_mhc_overview",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "",
        MHCclass            = "MHC1",
        ResultsOverwrite    = TRUE,
        PlotsSave           = TRUE,
        CsvSave             = TRUE
      ),
      output_file = "sim_01_mhc_overview.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
  # build mode also wrote the pep_all cache it parsed
  expect_true(file.exists(file.path(proj, "sim_fragpipe_dda", "pep_all.rda")))

  # the always-written exports of all five former reports
  expect_true(file.exists(file.path(proj, "01_mhc_overview_input_params.csv")))
  for (f in c("pep_all.csv", "counts_pep_all_condition.csv", "scores.csv",
              "red_flags.csv"))
    expect_true(file.exists(file.path(proj, f)), info = f)
  expect_true(file.exists(file.path(proj, "seq_by_condition.xlsx")))
  # ... and the CsvSave tier of each section (counts, overlaps, quant)
  for (f in c("counts_all.csv", "upset_table_unique.csv", "pep_overlap.csv",
              "pep_all_log2area_tr.csv"))
    expect_true(file.exists(file.path(proj, f)), info = f)

  # PlotsSave really writes files: ggsave_rawr used to resolve the plot name from
  # the package namespace outwards, never reaching the knit environment, so every
  # report saved nothing at all under PlotsSave = TRUE
  expect_gt(length(list.files(proj, pattern = "[.]png$")), 0)

  # the exported score table carries Condition (v0.24.0), for compare_runs()
  sc <- utils::read.csv(file.path(proj, "scores.csv"))
  expect_true("Condition" %in% names(sc))
  expect_false(anyNA(sc$Condition))
  expect_setequal(unique(sc$Condition), c("CTRL", "TREAT"))
  # ... and compare_runs() finds the new input-params name next to it
  runs <- compare_runs(file.path(proj, "scores.csv"))
  expect_equal(unique(runs$MHCclass), "MHC1")
  expect_equal(unique(runs$SampleSet), "sim")

  flags <- utils::read.csv(file.path(proj, "red_flags.csv"))
  expect_named(flags, c("Sample", "Severity", "Flag", "Detail"))

  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  # one heading from each merged report, in the order they now appear
  headings <- c("At a glance", "Red flags", "Identification counts",
                "Peptide size distribution", "Quality score",
                "Overlap of identifications", "Correlation log2(Area)",
                "Peptide motifs", "PTM profile", "Where to go next",
                "Appendix: quality-score method", "Glossary")
  # top-level headings as rendered (number_sections prefixes a numbered <span>)
  h1 <- regmatches(html, gregexpr("(?s)<h1[^>]*>.*?</h1>", html, perl = TRUE))[[1]]
  h1 <- gsub("<span[^>]*>[0-9.]+</span>", "", h1)
  h1 <- trimws(gsub("\\s+", " ", gsub("<[^>]+>", "", h1)))
  pos <- vapply(headings, function(h) match(TRUE, startsWith(h1, h)), integer(1))
  expect_false(anyNA(pos), info = paste(headings[is.na(pos)], collapse = ", "))
  expect_false(is.unsorted(pos, na.rm = TRUE))
  # the plots reach the HTML (ggprint_rawr had the same scoping bug as ggsave_rawr)
  expect_gt(length(gregexpr("<img", html)[[1]]), 10)
  # the red-flag section shows either the table or the explicit all-clear
  if (nrow(flags) == 0) {
    expect_true(grepl("No red flags.", html, fixed = TRUE))
  } else {
    expect_true(grepl(flags$Flag[1], html, fixed = TRUE))
  }
  # the redundant 09_overview sections are gone
  expect_false(grepl("How many ligands per sample", html, fixed = TRUE))
})

test_that("05_quant_stats renders end-to-end against the simulated data", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("limma")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("simquant_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "05_quant_stats",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "",
        MHCclass            = "MHC1",
        PeptideSet          = "selected",
        StatMethod          = "limma",
        NormMethod          = "median",
        ImputeMethod        = "none",
        PermutationTest     = TRUE,
        HeatmapClusters     = 3,
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = TRUE
      ),
      output_file = "sim_05_quant_stats.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
  # the statistical results are part of the always-written export tier
  expect_true(file.exists(file.path(proj, "quant_stats_results.csv")))
  expect_true(file.exists(file.path(proj, "quant_stats_summary.csv")))

  summ <- utils::read.csv(file.path(proj, "quant_stats_summary.csv"))
  expect_equal(nrow(summ), 1L)             # one contrast: TREAT vs CTRL
  expect_gt(summ$n_tested, 0)

  # the clustered heatmap's feature clusters reach the CsvSave export
  cl <- utils::read.csv(file.path(proj, "heatmap_clusters.csv"))
  expect_named(cl, c("Feature", "Cluster"))
  expect_setequal(unique(cl$Cluster), c("C1", "C2", "C3"))
})

test_that("a single-Condition subset renders (combn(conditions, 2) regression)", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("simone_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  # keep only the CTRL samples -> one Condition, which used to abort every report
  # in the shared setup chunk with "n < m" from combn(conditions, 2)
  one_cond <- derive_filtered_annotation("sim_fragpipe_dda_annotation.csv", proj, "CTRL")
  expect_true(file.exists(one_cond))
  expect_equal(dplyr::n_distinct(read_annot(one_cond)$Condition), 1L)

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "01_mhc_overview",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = basename(one_cond),
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "ctrl",
        MHCclass            = "MHC1",
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = FALSE
      ),
      output_file = "sim_01_mhc_overview_one_condition.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
})

test_that("the mouse MHC-I window reaches a rendered report", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("simmouse_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "01_mhc_overview",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "",
        MHCclass            = "MHC1_mouse",
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = FALSE
      ),
      output_file = "sim_01_mhc_overview_mouse.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
  html <- readLines(out, warn = FALSE)
  expect_true(any(grepl("7 to 11 AAs", html, fixed = TRUE)))   # the mouse window is in force
  expect_true(any(grepl("MHC1_mouse", html, fixed = TRUE)))    # ... and named in the title
})

test_that("04_pepchem renders end-to-end against the simulated data", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("simpepchem_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "04_pepchem",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "",
        MHCclass            = "MHC1",
        PeptideSet          = "selected",
        PropertySet         = "extended",
        MotifLength         = "auto",
        TerminalPositions   = "1,2,-2,-1",
        MinPeptidesSample   = 10,
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = FALSE
      ),
      output_file = "sim_04_pepchem.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
  # both always-written exports of this report
  expect_true(file.exists(file.path(proj, "pepchem_summary.csv")))
  expect_true(file.exists(file.path(proj, "pepchem_stats.csv")))

  summ <- utils::read.csv(file.path(proj, "pepchem_summary.csv"))
  expect_true(all(c("Sample", "Condition", "Property", "Median") %in% names(summ)))
  expect_true("GRAVY" %in% summ$Property)

  stats <- utils::read.csv(file.path(proj, "pepchem_stats.csv"))
  expect_equal(unique(stats$Contrast), "TREAT_vs_CTRL")
  expect_equal(unique(stats$Level), "sample")
  # the descriptors really were compared across the 3 vs 3 samples
  expect_equal(unique(c(stats$n1, stats$n2)), 3L)

  # the shared glossary carries the descriptor table in this report only
  # (pandoc re-wraps the HTML, so match on whitespace-collapsed text)
  html <- gsub("\\s+", " ", paste(readLines(out, warn = FALSE), collapse = " "))
  expect_match(html, "<caption> ?Physicochemical descriptors ?</caption>")
  expect_match(html, "Kyte-Doolittle hydropathy of the residues", fixed = TRUE)
})

test_that("04_pepchem renders for a single Condition (no comparison possible)", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("simpepchem1_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  annot <- utils::read.csv(file.path(proj, basename(sim_annot)))
  utils::write.csv(annot[annot$Condition == "CTRL", ],
                   file.path(proj, "annot_ctrl.csv"), row.names = FALSE)

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "04_pepchem",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = "annot_ctrl.csv",
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "ctrl",
        MHCclass            = "MHC1",
        MinPeptidesSample   = 10,
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = FALSE
      ),
      output_file = "sim_04_pepchem_ctrl.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
  # the descriptive summary is still written; the stats table is not
  expect_true(file.exists(file.path(proj, "ctrl", "ctrl_pepchem_summary.csv")))
  expect_false(file.exists(file.path(proj, "ctrl", "ctrl_pepchem_stats.csv")))
})

# Provider guard (v0.17.0): the report header attribution moved from hardcoded
# text in nine skeletons to the optional `Provider` param. This asserts it in
# BOTH directions -- a param that is declared but never reaches the output would
# pass a YAML-only check while silently changing nothing.

test_that("the Provider param reaches the rendered report, and is generic when unset", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("simprovider_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  base_params <- list(
    SampleSet           = "sim",
    Software            = "fragpipe_dda_individual",
    Instrument          = "tims_tof",
    FolderDocumentation = proj,
    AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
    FolderData          = file.path(proj, "sim_fragpipe_dda"),
    FolderResults       = proj,
    FolderFigures       = proj,
    ProjectDir          = proj,
    PepAllSource        = "build",
    Subset              = "",
    MHCclass            = "MHC1",
    ResultsOverwrite    = TRUE,
    PlotsSave           = FALSE,
    CsvSave             = FALSE
  )

  named <- suppressWarnings(suppressMessages(run_howmahico_report(
    "01_mhc_overview",
    params = c(base_params, list(Provider = "Test Platform (TP)")),
    output_file = "sim_provider_named.html", quiet = TRUE)))
  html_named <- paste(readLines(named, warn = FALSE), collapse = "\n")

  expect_true(grepl("Provided by Test Platform (TP).", html_named, fixed = TRUE))
  expect_false(grepl("Generated with the HowMaHiCo R package", html_named, fixed = TRUE))

  # and the param is recorded for reproducibility
  ip <- utils::read.csv(file.path(proj, "01_mhc_overview_input_params.csv"))
  expect_equal(ip$Value[ip$Parameter == "Provider"], "Test Platform (TP)")

  unset <- suppressWarnings(suppressMessages(run_howmahico_report(
    "01_mhc_overview", params = base_params,
    output_file = "sim_provider_unset.html", quiet = TRUE)))
  html_unset <- paste(readLines(unset, warn = FALSE), collapse = "\n")

  expect_true(grepl("Generated with the HowMaHiCo R package", html_unset, fixed = TRUE))
  expect_false(grepl("Provided by", html_unset, fixed = TRUE))
  # no residual branding from the pre-v0.17.0 hardcoded header. Match the full
  # contact string, not a bare "dkfz": a self-contained report embeds fonts as
  # base64, and any short alphanumeric run turns up in that blob by chance. "@"
  # and "." are outside the base64 alphabet, so this cannot false-positive.
  expect_false(grepl("Immunopeptidomics Platform", html_unset, fixed = TRUE))
  expect_false(grepl("@dkfz.de", html_unset, fixed = TRUE))
})

test_that("02_prot_all renders end-to-end against the simulated data", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("simprot_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "02_prot_all",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "",
        MHCclass            = "MHC1",
        PeptideSet          = "all",
        ProteinFeature      = "ProteinFirst",
        MultiMapping        = "leading",
        TopNProteins        = 15,
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = FALSE
      ),
      output_file = "sim_02_prot_all.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
  expect_true(file.exists(file.path(proj, "prot_all.csv")))
  expect_true(file.exists(file.path(proj, "prot_summary.csv")))

  prot <- utils::read.csv(file.path(proj, "prot_all.csv"))
  expect_true(all(c("Protein", "Sample", "Condition", "n_Peptides", "n_Sequences",
                    "Area", "Log2Area") %in% names(prot)))
  # one row per (protein, sample), and the proteins are the pep_all ones
  expect_equal(nrow(prot), nrow(unique(prot[, c("Protein", "Sample")])))
  expect_equal(length(unique(prot$Protein)), 413L)

  # FragPipe reports no protein quantity, so that section degrades to its note.
  # Assert the absence on the exported table rather than the HTML: the Methods
  # section names PG.MaxLFQ in prose, so the string is legitimately in the report.
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_true(grepl("reports no protein-level values", html, fixed = TRUE))
  expect_equal(intersect(diann_protein_columns(), names(prot)), character(0))
})

test_that("02_prot_all falls back to leading proteins when none are mapped", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  # The shipped fixture's `Mapped Proteins` column is blank in every row, so
  # MultiMapping = "all" has nothing to expand and must degrade to "leading"
  # rather than fail -- which is also what a PEAKS or custom-dictionary run does.
  proj <- tempfile("simprotall_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "02_prot_all",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "mm",
        MHCclass            = "MHC1",
        MultiMapping        = "all",
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = FALSE
      ),
      output_file = "sim_02_prot_all_mm.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
  prot <- utils::read.csv(file.path(proj, "mm", "mm_prot_all.csv"))
  # no protein was invented by the expansion
  expect_equal(length(unique(prot$Protein)), 413L)
  expect_true(all(prot$n_Peptides_shared == 0))
})

# InteractivePlots (v0.21.0) can only be verified by rendering: ggplotly() returns
# an htmlwidget, and a widget that does not get its dependencies attached renders
# as an EMPTY tab with no error and no failing expectation. So this asserts the
# widget markers really reach the HTML, in both directions.

test_that("InteractivePlots puts plotly widgets in the HTML, and FALSE keeps them out", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("plotly")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("siminter_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  render_main <- function(interactive, output) {
    suppressWarnings(suppressMessages(
      run_howmahico_report(
        "01_mhc_overview",
        params = list(
          SampleSet           = "sim",
          Software            = "fragpipe_dda_individual",
          Instrument          = "tims_tof",
          FolderDocumentation = proj,
          AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
          FolderData          = file.path(proj, "sim_fragpipe_dda"),
          FolderResults       = proj,
          FolderFigures       = proj,
          ProjectDir          = proj,
          PepAllSource        = "build",
          Subset              = "",
          MHCclass            = "MHC1",
          InteractivePlots    = interactive,
          ResultsOverwrite    = TRUE,
          PlotsSave           = FALSE,
          CsvSave             = FALSE
        ),
        output_file = output,
        quiet = TRUE)))
  }

  out_on <- render_main(TRUE, "sim_01_interactive.html")
  expect_true(file.exists(out_on))
  html_on <- paste(readLines(out_on, warn = FALSE), collapse = "\n")
  # the widget containers and the embedded plotly library both have to be there:
  # containers without the library is exactly the silent-empty-plot failure
  expect_match(html_on, "plotly html-widget", fixed = TRUE)
  expect_match(html_on, "plotly.js", fixed = TRUE)
  n_widgets <- function(html)
    lengths(regmatches(html, gregexpr("plotly html-widget", html, fixed = TRUE)))
  n_on <- n_widgets(html_on)

  out_off <- render_main(FALSE, "sim_01_static.html")
  expect_true(file.exists(out_off))
  html_off <- paste(readLines(out_off, warn = FALSE), collapse = "\n")
  n_off <- n_widgets(html_off)
  # with the toggle off, only the two log2(Area) correlation matrices (always
  # interactive, by design since v0.1) remain widgets ...
  expect_lte(n_off, 2L)
  # ... and the toggle converts at least the quality-score composite and
  # per-metric heatmap, the cross-class histogram and the Area %CV violins
  expect_gte(n_on - n_off, 3L)
})
