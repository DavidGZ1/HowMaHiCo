#' Save a ggplot to a folder, skipping plots that were never built
#'
#' Looks up `input` by the name it was called with (via `deparse(substitute())`)
#' and only calls [ggplot2::ggsave()] if an object of that name exists in the
#' calling environment — this lets report chunks unconditionally call
#' `ggsave_rawr(p_some_plot, "some_plot", folder = FolderFigures)` even when
#' `p_some_plot` was conditionally skipped upstream (e.g. no non-NA correlation
#' to plot), without erroring.
#'
#' Reconciles two near-duplicate report-inline variants (one hardcoding
#' `"4_figures"`, the other a `width = n_conditions + 5` default and a
#' chunk-local `FolderFigures`) into a single canonical version that takes
#' `folder`/`width`/`height` as ordinary explicit arguments — callers compute
#' and pass whatever values their report context needs.
#'
#' @param input The plot object to save (NSE: its variable name is used to
#'   check existence, not its value).
#' @param file Output file name, without extension; saved as `<file>.png`
#'   under `folder`.
#' @param folder Destination directory for the png.
#' @param width,height Figure dimensions in cm, passed to [ggplot2::ggsave()].
#'
#' @return Invisible `NULL`; called for its side effect of writing a png (or
#'   warning that it was skipped).
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' ggsave_rawr(p_peplength_all, "peplength_all", folder = FolderFigures)
#' }
ggsave_rawr <- function(input, file, folder, width = 8, height = 10) {
  if(exists(deparse(substitute(input))) == TRUE){
    ggplot2::ggsave(file.path(folder, paste0(file, ".png")), input, device = "png",
                    scale = 1, width = width, height = height, units = "cm")
  }else{
    warning(paste0(file, ".png was not saved because the plot was not generated"))
  }
}

#' Write a data frame to csv, named after the variable that was passed in
#'
#' Looks up the name `input` was called with (via `deparse(substitute())`) and
#' writes it to `<folder>/<prefix>_<name>.csv` (or `<folder>/<name>.csv` when
#' `prefix` is `NULL`) — an intentional NSE pattern that lets ~30 export call
#' sites stay terse (`write.csv_rawr(counts_pep_all_condition)`) while the
#' output filename always matches the object name.
#'
#' Reconciles three near-duplicate report-inline variants (a plain
#' `folder = FolderResults`-defaulting version, and two that additionally
#' prefixed the filename with `params$Subset`) into one canonical signature
#' that takes both `folder` and an optional `prefix` explicitly.
#'
#' @param input The data frame to write (NSE: its variable name becomes the
#'   filename).
#' @param folder Destination directory for the csv.
#' @param prefix Optional string prepended to the filename as
#'   `"<prefix>_<name>.csv"`; when `NULL` (the default) the filename is just
#'   `"<name>.csv"`.
#'
#' @return Invisible `NULL`; called for its side effect of writing a csv.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' write.csv_rawr(counts_pep_all_condition, folder = FolderResults)
#' write.csv_rawr(counts_pep_all_wide, folder = FolderResults, prefix = params$Subset)
#' }
write.csv_rawr <- function(input, folder, prefix = NULL){
  filename <- if(is.null(prefix)){
    paste0(deparse(substitute(input)), ".csv")
  }else{
    paste0(prefix, "_", deparse(substitute(input)), ".csv")
  }
  write.csv(input, file.path(folder, filename), row.names = FALSE)
}
