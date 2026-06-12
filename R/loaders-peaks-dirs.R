#' List and classify PEAKS export subfolders
#'
#' Lists the subdirectories under `directory`, classifies each by export type
#' (PEAKS / PEAKS PTM / SPIDER / QC variants) and mode (DB / LIB) inferred from
#' the folder-naming convention, and extracts the project name and PEAKS file
#' number from the folder name.
#'
#' @param directory Path to the top-level folder containing PEAKS export
#'   subfolders.
#' @param recursive Passed to [list.dirs()]; whether to list subdirectories
#'   recursively.
#' @param drop_unknowns If `TRUE` (default), rows whose `Type` could not be
#'   classified (folder name doesn't match any known PEAKS export pattern) are
#'   dropped.
#'
#' @return A data frame with one row per matching subdirectory and columns
#'   `path_full`, `QC`, `Mode`, `Type`, `Project`, `File_peaks_nb`.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' get_dirs_index_peaks("2_data/peaks_xpro")
#' }
get_dirs_index_peaks <- function(directory, recursive = TRUE, drop_unknowns = TRUE) {
  output <- data.frame(path_full = list.dirs(directory, recursive = recursive)) |>
    dplyr::filter(!stringr::str_ends(path_full, "\\img")) |>
    dplyr::mutate(
      QC = ifelse(grepl("_QC_", path_full), TRUE, FALSE),
      Mode = ifelse(grepl("LIB", path_full), "LIB", "DB"),
      Type = dplyr::case_when(
        grepl("PEAKS PTM_", path_full) ~ "PEAKS PTM",
        grepl("SPIDER_", path_full) ~ "SPIDER",
        grepl("PEAKS_|PEAKSLIB_", path_full) ~ "PEAKS",
        TRUE ~ "Unknown"
      ),
      Type = ifelse(QC == TRUE, paste0("QC_", Type), Type),
      Folder = gsub(paste0(directory, "/"), "", path_full),
      Project = stringr::str_extract(Folder, pattern = paste0(".+?(?=_", Type, ")")),
      File_peaks_nb = stringr::str_replace(Folder, pattern = paste0(Project, "_", Type, "_"), replacement = "")
    ) |>
    dplyr::select(-Folder)

  if (drop_unknowns == TRUE) {
    output <- output[output$Type != "Unknown", ]
  }

  return(output)
}
