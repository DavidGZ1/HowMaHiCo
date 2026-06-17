#' Render a HowMaHiCo QC report from the installed package templates
#'
#' Thin wrapper around [rmarkdown::render()] that locates one of the package's
#' two report templates via [system.file()] and renders it with the supplied
#' `params`. One call renders one report — composable (loop it for batch runs,
#' see `derive_filtered_annotation()`/the batch-rendering example below) and
#' Docker-idiomatic ("one container run = one job").
#'
#' `FolderData`/`FolderResults`/`FolderFigures` in `params` are **absolute
#' paths** (or paths relative to the current working directory at render
#' time) — unlike the legacy `0_code/`-era reports, the rendered template no
#' longer assumes a fixed project-root-relative layout, since it now lives
#' inside an installed package and can be rendered from anywhere.
#'
#' @param template Which report template to render. `"00_mhc_report"` is the
#'   all-in-one QC report (it parses the raw search files itself). The remaining
#'   templates are focused reports that render against a `pep_all` cache built
#'   once by [build_pep_all()] (or by `00_mhc_report`):
#'   `"00_mhc_upsets"` (per-sample overlap/UpSet), `"01_id_counts"` (general
#'   identification QC: counts, size distributions, motifs, PTM), `"02_overlaps"`
#'   (intra-Condition / cross-Condition / pairwise overlap), `"03_lcms_qc"`
#'   (RT/1k0/mz distributions, Score/ppm QC), `"04_quant"`
#'   (log2(Area) correlation, Area %CV), and `"05_quality_score"` (per-sample
#'   immunopeptidomics quality score with a traffic-light overview).
#' @param params Named list of report parameters, as declared in the
#'   template's YAML header (`SampleSet`, `AnnotationFile`, `Subset`,
#'   `FolderData`, `FolderResults`, `FolderFigures`, `Software`, `MHCclass`,
#'   ...). The report title is auto-generated from `SampleSet`, `Subset`,
#'   `MHCclass`, and the render date — no `Title` param needed. Key params:
#'   `MHCclass` — `"MHC1"` (8-13 AA window, default) or `"MHC2"` (12-25 AA
#'   window); overrides `ShortPeptideLengthMin`/`ShortPeptideLengthMax` when set
#'   to a recognised value. Pass `ProjectDir = "/absolute/path/to/project"` to
#'   resolve relative folder paths from that directory instead of the current
#'   working directory — useful when R is started from a subdirectory.
#' @param output_file Output HTML file path. Relative paths are resolved
#'   against `params$ProjectDir` (if supplied) or the current working directory
#'   at call time — never against the package-internal skeleton location.
#' @param ... Additional arguments forwarded to [rmarkdown::render()] (e.g.
#'   `quiet`, `envir`).
#'
#' @return The path to the rendered output file (invisibly), as returned by
#'   [rmarkdown::render()].
#'
#' @export
#'
#' @examples
#' \dontrun{
#' run_howmahico_report(
#'   template = "00_mhc_report",
#'   params = list(SampleSet = "MEGF_035_K251128",
#'                 AnnotationFile = "sample_annotation_dda_all.csv",
#'                 Subset = "dda_all",
#'                 FolderData = "/data/2_data",
#'                 FolderResults = "/data/3_results",
#'                 FolderFigures = "/data/4_figures",
#'                 Software = "fragpipe_dda_combined"),
#'   output_file = "01_report_main__hla1_dda_all.html"
#' )
#'
#' # Focused-report framework: build the pep_all cache once, then render any
#' # subset of the focused reports against it (no re-parsing per report).
#' annot <- read_annot("1_documentation/sample_annotation_dda_all.csv")
#' build_pep_all(software = "fragpipe_dda_combined", folder_data = "2_data",
#'               annotation = annot, shortpep_range = c(8, 13),
#'               file_rda = "2_data/dda_all_pep_all.rda")
#' focused_params <- list(SampleSet = "MEGF_035", Subset = "dda_all",
#'                        FolderData = "2_data", FolderResults = "3_results",
#'                        FolderFigures = "4_figures", Software = "fragpipe_dda_combined")
#' for (tmpl in c("01_id_counts", "02_overlaps", "03_lcms_qc", "04_quant")) {
#'   run_howmahico_report(tmpl, params = focused_params,
#'                        output_file = paste0(tmpl, "__dda_all.html"))
#' }
#'
#' # Batch-rendering pattern (preserves 00_knit_reports.R's 6-subset loop):
#' annot_jy <- derive_filtered_annotation("sample_annotation_dda_all.csv",
#'                                        "1_documentation", "JY")
#' for (subset in c("dda_all", "dda_jy", "dda_plasma")) {
#'   run_howmahico_report(template = "00_mhc_report",
#'                        params = list(Subset = subset, ...),
#'                        output_file = paste0("01_report_main__hla1_", subset, ".html"))
#' }
#' }
run_howmahico_report <- function(template = c("00_mhc_report", "00_mhc_upsets",
                                              "01_id_counts", "02_overlaps",
                                              "03_lcms_qc", "04_quant"),
                                 params, output_file, ...){
  template <- match.arg(template)
  skeleton <- system.file("rmarkdown", "templates", template, "skeleton", "skeleton.Rmd",
                          package = "HowMaHiCo")
  # render() defaults to knitting in parent.frame() — that's *this* function's
  # own environment, which already binds a `params` argument and collides with
  # the `params` rmarkdown injects into the knit environment. Knit in a fresh
  # environment instead.
  knit_root_dir <- if (!is.null(params$ProjectDir) && nzchar(params$ProjectDir))
    normalizePath(params$ProjectDir, mustWork = FALSE) else NULL
  # Resolve output_file against the project root (or cwd) so a bare filename
  # doesn't land inside the package library next to skeleton.Rmd.
  base_dir <- if (!is.null(knit_root_dir)) knit_root_dir else getwd()
  output_file <- normalizePath(file.path(base_dir, output_file), mustWork = FALSE)
  rmarkdown::render(input = skeleton, output_file = output_file, params = params,
                    knit_root_dir = knit_root_dir,
                    envir = new.env(parent = globalenv()), ...)
}

#' Derive a Condition-filtered copy of a sample annotation file
#'
#' Reads `annotation_file` from `folder`, keeps only rows whose `Condition`
#' matches `pattern` (via [grepl()]), and writes the result alongside it as
#' `<stem>_<suffix>.csv` — the preprocessing step `00_knit_reports.R` ran once
#' to derive the `_jy`/`_plasma` annotation subsets from `_all` before
#' batch-rendering per-subset reports.
#'
#' @param annotation_file Name of the source annotation csv (in `folder`),
#'   e.g. `"sample_annotation_dda_all.csv"`.
#' @param folder Directory containing `annotation_file` (and where the
#'   filtered copy is written), e.g. `"1_documentation"`.
#' @param pattern Regular expression matched against `Condition` via
#'   [grepl()] to select rows, e.g. `"JY"` or `"Plasma"`.
#' @param suffix Suffix appended to the filename stem to name the filtered
#'   copy (defaults to `tolower(pattern)`).
#'
#' @return The path to the written filtered annotation csv (invisibly).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' derive_filtered_annotation("sample_annotation_dda_all.csv", "1_documentation", "JY")
#' derive_filtered_annotation("sample_annotation_dda_all.csv", "1_documentation", "Plasma")
#' }
derive_filtered_annotation <- function(annotation_file, folder, pattern, suffix = tolower(pattern)){
  stem <- sub("_all\\.csv$", "", annotation_file)
  output_file <- file.path(folder, paste0(stem, "_", suffix, ".csv"))
  utils::read.csv(file.path(folder, annotation_file)) |>
    dplyr::filter(grepl(pattern, Condition)) |>
    utils::write.csv(output_file, row.names = FALSE)
  invisible(output_file)
}
