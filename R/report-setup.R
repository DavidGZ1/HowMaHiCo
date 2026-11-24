#' Set up the objects a HowMaHiCo report works on
#'
#' The setup step shared by the focused report templates (`01_mhc_overview`,
#' `02_prot_all`, `03_lcms_qc`, `04_pepchem`, `05_quant_stats`), as an ordinary
#' function so that a report can be run, chunk by chunk, outside a knit. It
#' derives the peptide-length window and palette, the output folders, loads (or
#' builds) `pep_all`, and derives `pep_short` plus the grouping vectors every
#' section reuses, then assigns all of them into `envir`.
#'
#' `pep_all` is obtained according to `params$PepAllSource`:
#' * `"cached"` (default): load `<FolderData>/<Subset>_pep_all.rda`.
#' * `"rda"`: load the file given by `params$PepAllFile`.
#' * `"build"`: parse the raw search output with [build_pep_all()] (reading
#'   `params$AnnotationFile` from `params$FolderDocumentation`) and write the
#'   cache.
#'
#' To step through a report interactively:
#' ```r
#' library(HowMaHiCo)
#' params <- report_params("03_lcms_qc", Subset = "dda_all", FolderData = "2_data")
#' report_setup(params)   # pep_all, pep_short, shortpep_range, ... now exist
#' # then run the remaining chunks of the skeleton (see get_report_template())
#' ```
#'
#' @param params Named list of report parameters, normally from
#'   [report_params()] (inside a knit, the `params` rmarkdown provides). Missing
#'   optional entries (`PepAllSource`, `InteractivePlots`, `ResultsOverwrite`,
#'   `Subset`, ...) fall back to the template defaults.
#' @param envir Environment the objects are assigned into. Defaults to the
#'   calling frame: the knit environment in a report, the global environment at
#'   the console.
#'
#' @return Invisibly, a named list of the assigned objects: `shortpep_range`,
#'   `shortpep_palette`, `shortpep_colors`, `interactive_plots`, `subset`,
#'   `FolderResults`, `FolderFigures`, `result_prefix`, `file_rda`, `pep_all`,
#'   `pep_short`, `samples`, `conditions`, `n_conditions`, `bioreplicates`,
#'   `comp_condition`, `phis_nrow` and `phis_ncol`.
#'
#' @seealso [report_params()], [get_report_template()], [run_howmahico_report()]
#' @export
#'
#' @examples
#' \dontrun{
#' params <- report_params("01_mhc_overview", Subset = "dda_all",
#'                         FolderData = "2_data", FolderResults = "3_results")
#' report_setup(params)
#' table(pep_all$Condition)
#' }
report_setup <- function(params, envir = parent.frame()) {
  p <- .report_param_defaults(params)

  # length window + palette of the MHC class (MHC1 8-13, MHC1_mouse 7-11,
  # MHC2 12-25; anything else falls back to the ShortPeptideLength* params)
  shortpep_range <- mhc_length_window(p$MHCclass,
                                      min = p$ShortPeptideLengthMin,
                                      max = p$ShortPeptideLengthMax)
  shortpep_palette <- mhc_class_palette(p$MHCclass)
  shortpep_colors <- stats::setNames(shortpep_palette,
    c(paste0(shortpep_range[1], " to ", shortpep_range[2], " AAs"), "others"))

  # interactive plots: plotly widgets instead of static ggplots, for the plots
  # printed from ordinary chunks (results='asis' tabset loops stay static)
  interactive_plots <- isTRUE(p$InteractivePlots)

  if (p$Subset == "") {
    subset <- ""
    FolderResults <- p$FolderResults
    FolderFigures <- p$FolderFigures
  } else {
    subset <- paste0(p$Subset, "_")
    dir.create(file.path(p$FolderResults, p$Subset), showWarnings = FALSE,
               recursive = TRUE)
    dir.create(file.path(p$FolderFigures, p$Subset), showWarnings = FALSE,
               recursive = TRUE)
    FolderResults <- file.path(p$FolderResults, p$Subset)
    FolderFigures <- file.path(p$FolderFigures, p$Subset)
  }

  # subset prefix applied to every result filename (NULL when no Subset is set,
  # so write.csv_rawr() falls back to the bare object name)
  result_prefix <- if (p$Subset == "") NULL else p$Subset

  file_rda <- file.path(p$FolderData, paste0(subset, "pep_all.rda"))

  # pre-check to avoid overwriting prior outputs (the reports read, not write,
  # the pep_all cache, so only the output folder is guarded here)
  check_output_exists(p$FolderResults, overwrite = p$ResultsOverwrite)

  pep_all <- .report_load_pep_all(p, file_rda, shortpep_range)

  pep_short <- dplyr::filter(pep_all, Length >= shortpep_range[1],
                             Length <= shortpep_range[2])

  # simplified info reused across sections
  samples <- levels(pep_all$Sample)
  conditions <- levels(pep_all$Condition)
  n_conditions <- length(conditions)
  bioreplicates <- levels(pep_all$BioReplicate)
  comp_condition <- condition_pairs(conditions)   # empty list for one Condition

  # facet layout reused by the size-distribution, RT/1k0/mz and motif sections
  if (length(conditions) <= 3) {
    phis_nrow <- 1
    phis_ncol <- length(conditions)
  } else {
    phis_nrow <- 3
    phis_ncol <- ceiling(length(conditions) / 3)
  }

  out <- list(shortpep_range = shortpep_range, shortpep_palette = shortpep_palette,
              shortpep_colors = shortpep_colors, interactive_plots = interactive_plots,
              subset = subset, FolderResults = FolderResults,
              FolderFigures = FolderFigures, result_prefix = result_prefix,
              file_rda = file_rda, pep_all = pep_all, pep_short = pep_short,
              samples = samples, conditions = conditions,
              n_conditions = n_conditions, bioreplicates = bioreplicates,
              comp_condition = comp_condition, phis_nrow = phis_nrow,
              phis_ncol = phis_ncol)
  # assign() rather than list2env(): result_prefix may be NULL and must still
  # exist as a binding
  for (nm in names(out)) assign(nm, out[[nm]], envir = envir)
  invisible(out)
}

# Fill in the params report_setup() reads but a hand-made list may omit.
.report_param_defaults <- function(params) {
  defaults <- list(Subset = "", FolderData = "2_data",
                   FolderResults = "3_results", FolderFigures = "4_figures",
                   FolderDocumentation = "1_documentation",
                   AnnotationFile = "samples_annotation.csv",
                   PepAllSource = "cached", PepAllFile = "",
                   Software = "fragpipe_dda_combined", Instrument = "tims_tof",
                   MHCclass = "MHC1", ShortPeptideLengthMin = 8,
                   ShortPeptideLengthMax = 13, TestMode = FALSE,
                   ResultsOverwrite = TRUE, InteractivePlots = FALSE)
  params <- as.list(params)
  for (nm in names(defaults)) {
    v <- params[[nm]]
    if (is.null(v) || (length(v) == 1 && is.na(v))) params[[nm]] <- defaults[[nm]]
  }
  if (!nzchar(params$PepAllSource)) params$PepAllSource <- "cached"
  params
}

# Load or build pep_all according to params$PepAllSource.
.report_load_pep_all <- function(p, file_rda, shortpep_range) {
  load_rda <- function(path) {
    e <- new.env()
    load(path, envir = e)            # restores `pep_all`
    if (!exists("pep_all", envir = e, inherits = FALSE))
      stop("'", path, "' does not contain a 'pep_all' object", call. = FALSE)
    e$pep_all
  }
  switch(p$PepAllSource,
    cached = {
      if (!file.exists(file_rda))
        stop("pep_all cache not found at '", file_rda, "'.\n",
             "Build it first with build_pep_all(..., file_rda = '", file_rda, "'), ",
             "render 00_mhc_report (which writes the cache), or set ",
             "PepAllSource = 'build' to parse the raw results here.", call. = FALSE)
      message("pep_all: loading the cache '", file_rda, "'")
      load_rda(file_rda)
    },
    rda = {
      f <- p$PepAllFile
      if (is.null(f) || !nzchar(f) || !file.exists(f))
        stop("PepAllSource = 'rda' but PepAllFile '", f, "' was not found.",
             call. = FALSE)
      message("pep_all: loading '", f, "'")
      load_rda(f)
    },
    build = {
      annot_file <- file.path(p$FolderDocumentation, p$AnnotationFile)
      message("pep_all: building from '", p$FolderData, "' with the annotation '",
              annot_file, "'")
      annot <- read_annot(annot_file)
      build_pep_all(software = p$Software, folder_data = p$FolderData,
                    annotation = annot, shortpep_range = shortpep_range,
                    instrument = p$Instrument, test_mode = p$TestMode,
                    file_rda = file_rda)
    },
    stop("Unknown PepAllSource '", p$PepAllSource,
         "'. Use 'cached', 'rda', or 'build'.", call. = FALSE)
  )
}

#' Build the parameter list of a HowMaHiCo report
#'
#' Reads the parameters a report template declares in its YAML header, with
#' their default values, and overlays the values given in `...`. Use it to get
#' a `params` list outside a knit (to run a report's chunks at the console with
#' [report_setup()] and the chunks of a skeleton copied by [get_report_template()]).
#' [run_howmahico_report()] uses it too, so a misspelled parameter fails before
#' the render starts, with the list of valid names.
#'
#' @param template Report template name, as for [run_howmahico_report()]
#'   (names used before v0.27.0 are resolved with a warning).
#' @param ... Parameter values overriding the template defaults, as
#'   `Name = value` pairs.
#' @param .params Optional named list of parameter values, merged before `...`
#'   (handy for passing an existing list).
#'
#' @return A named list holding every parameter the template declares.
#'
#' @seealso [report_setup()], [get_report_template()]
#' @export
#'
#' @examples
#' p <- report_params("03_lcms_qc", Subset = "dda_all", MHCclass = "MHC2")
#' p$MHCclass
#' names(p)
report_params <- function(template, ..., .params = list()) {
  skeleton <- .report_skeleton(template)
  declared <- knitr::knit_params(readLines(skeleton, warn = FALSE, encoding = "UTF-8"))
  defaults <- lapply(declared, function(x) x$value)
  names(defaults) <- vapply(declared, function(x) x$name, character(1))

  user <- utils::modifyList(as.list(.params), list(...), keep.null = TRUE)
  unknown <- setdiff(names(user), names(defaults))
  if (length(unknown))
    stop("Template '", basename(dirname(dirname(skeleton))), "' does not declare ",
         "the parameter(s) ", paste0("'", unknown, "'", collapse = ", "), ".\n",
         "Valid parameters: ", paste(names(defaults), collapse = ", "), ".",
         call. = FALSE)
  # modifyList() drops NULL values; keep.null keeps an explicit NULL override
  utils::modifyList(defaults, user, keep.null = TRUE)
}

# Path of a template's installed skeleton.Rmd (aliases resolved).
.report_templates <- c("00_mhc_report", "00_mhc_upsets", "01_mhc_overview",
                       "02_prot_all", "03_lcms_qc", "04_pepchem", "05_quant_stats")

.report_skeleton <- function(template) {
  template <- .resolve_template_alias(template)
  template <- match.arg(template, .report_templates)
  system.file("rmarkdown", "templates", template, "skeleton", "skeleton.Rmd",
              package = "HowMaHiCo", mustWork = TRUE)
}
