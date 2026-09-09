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
#' A bare symbol is looked up by name in the **calling** environment; any other
#' expression (`plots[[nm]]`, a computed plot) is evaluated and judged by its
#' value, so the idiomatic
#' `for (nm in names(plots)) ggsave_rawr(plots[[nm]], file = nm, ...)` export
#' loop works as well.
#'
#' @param input The plot object to save. When it is a bare variable name, that
#'   name is used to check existence rather than the value.
#' @param file Output file name, without extension; saved as `<file>.png`
#'   under `folder`.
#' @param folder Destination directory for the png.
#' @param width,height Figure dimensions in cm, passed to [ggplot2::ggsave()].
#'
#' @return Invisible `NULL`; called for its side effect of writing a png (or
#'   warning that it was skipped).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ggsave_rawr(p_peplength_all, "peplength_all", folder = FolderFigures)
#' }
ggsave_rawr <- function(input, file, folder, width = 8, height = 10) {
  if (!.plot_was_built(substitute(input), parent.frame())) {
    warning(paste0(file, ".png was not saved because the plot was not generated"))
    return(invisible(NULL))
  }
  ggplot2::ggsave(file.path(folder, paste0(file, ".png")), input, device = "png",
                  scale = 1, width = width, height = height, units = "cm")
  invisible(NULL)
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
#' @export
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

#' Write a report's render parameters to csv
#'
#' Builds a one-row-per-parameter long-format data frame — package version,
#' render timestamp, then every entry of `params` flattened to a string — and
#' writes it via [write.csv_rawr()]. Deliberately a plain `input_params.csv`
#' rather than a prepended xlsx sheet (a documented deviation from the style
#' guide's "first sheet is always `input_params`" convention): assigning the
#' table to a local variable named `input_params` lets `write.csv_rawr()`'s
#' `deparse(substitute())` filename trick produce exactly
#' `<prefix>_input_params.csv` / `input_params.csv` for free.
#'
#' Always called once per render from the template's final export block,
#' independent of `CsvSave`/xlsx exports — `input_params.csv` is part of the
#' "always written" tier alongside `pep_all.csv`/
#' `counts_pep_all_condition.csv`/`seq_by_condition.xlsx`.
#'
#' @param params The Rmd `params` list passed to the report at render time.
#' @param folder Destination directory for the csv.
#' @param prefix Optional string prepended to the filename, forwarded to
#'   [write.csv_rawr()].
#'
#' @return Invisible `NULL`; called for its side effect of writing
#'   `input_params.csv`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' write_input_params(params, folder = FolderResults)
#' }
write_input_params <- function(params, folder, prefix = NULL){
  input_params <- data.frame(
    Parameter = c("package_version", "render_timestamp", names(params)),
    Value = c(as.character(utils::packageVersion("HowMaHiCo")),
              as.character(Sys.time()),
              vapply(params, function(x) paste(as.character(x), collapse = "; "), character(1)))
  )
  write.csv_rawr(input_params, folder, prefix)
}
