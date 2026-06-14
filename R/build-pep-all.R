#' Build (and optionally cache) the unified `pep_all` table from raw search output
#'
#' Reads, parses, and annotates LC-MS search-engine output into the unified
#' long-format `pep_all` table, dispatching on `software` to the right loader
#' family (FragPipe / DIA-NN / PEAKS). This is the parsing step that the
#' `00_mhc_report` template runs inline; extracting it here lets the focused
#' report templates (`01_id_counts`, `02_overlaps`, `03_lcms_qc`, `04_quant`)
#' share one cached `pep_all` instead of each re-parsing the raw files: run
#' `build_pep_all()` once (writing the `.rda` via `file_rda`), then render any
#' subset of those reports, each of which simply `load()`s the cache.
#'
#' @param software One of `"fragpipe_dda_combined"`, `"fragpipe_dda_individual"`,
#'   `"diann"`, or `"peaks_xpro"` — selects the loader branch (and, for FragPipe,
#'   the combined-vs-individual annotation mode).
#' @param folder_data Path to the folder holding the per-sample search output
#'   (the report's `FolderData`).
#' @param annotation Annotation data frame (e.g. from [read_annot()]); used to
#'   restrict the batch read to annotated samples and to join sample metadata.
#' @param shortpep_range Length-2 numeric vector `c(min, max)`; the
#'   biologically expected ligand-length window, forwarded to the `parse_*()`
#'   step to set `Length_range`.
#' @param instrument Instrument string (`"tims_tof"`, `"faims_orbi"`, `"orbi"`);
#'   only affects the PEAKS loader's ion-mobility handling.
#' @param test_mode If `TRUE`, the batch readers load only the first ~100 lines
#'   per file (fast iteration). Ignored by the PEAKS loader.
#' @param file_rda Optional path. When non-`NULL`, `pep_all` is `save()`d there
#'   (as the object name `pep_all`) so report templates can `load()` it.
#'
#' @return The `pep_all` data frame, invisibly.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' annot <- read_annot("1_documentation/sample_annotation_dda_all.csv")
#' build_pep_all(
#'   software       = "fragpipe_dda_combined",
#'   folder_data    = "2_data",
#'   annotation     = annot,
#'   shortpep_range = c(8, 13),
#'   file_rda       = "2_data/dda_all_pep_all.rda"
#' )
#' # then render any focused report against the cache:
#' run_howmahico_report("01_id_counts", params = list(...), output_file = "01.html")
#' }
build_pep_all <- function(software, folder_data, annotation,
                          shortpep_range = c(8, 13), instrument = "tims_tof",
                          test_mode = FALSE, file_rda = NULL) {
  if (grepl("fragpipe_dda", software)) {
    annot_mode <- if (grepl("combined", software)) {
      "combined_file"
    } else if (grepl("individual", software)) {
      "individual_files"
    } else {
      stop("please specify fragpipe_dda_individual or fragpipe_dda_combined")
    }
    pep_all <- read_fragpipe_batch(folder = folder_data, annotation = annotation,
                                   testmode = test_mode) |>
      parse_fragpipe(shortpep_range = shortpep_range) |>
      annotate_fragpipe(annotation, mode = annot_mode)
    warning("for Fragpipe, the psm file is currently being used. This means that FDR has not been applied at the peptide level, only at PSM level")
  } else if (software == "diann") {
    pep_all <- read_diann_batch(folder = folder_data, annotation = annotation,
                                testmode = test_mode) |>
      parse_diann(shortpep_range = shortpep_range) |>
      annotate_diann(annotation)
    warning("for DIA-NN, some columns are currently missing, including Mass and ppm (ppm = 0 as dummy)")
  } else if (software == "peaks_xpro") {
    pep_all <- read_peaks_batch(folder = folder_data, annotation = annotation,
                                instrument = instrument) |>
      parse_peaks(shortpep_range = shortpep_range) |>
      annotate_peaks(annotation)
  } else {
    stop("Unknown 'software': ", software,
         ". Expected one of fragpipe_dda_combined, fragpipe_dda_individual, diann, peaks_xpro.")
  }

  if (!is.null(file_rda)) save(pep_all, file = file_rda)
  invisible(pep_all)
}
