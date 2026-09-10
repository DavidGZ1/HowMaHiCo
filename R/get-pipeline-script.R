#' Copy the guided analysis-pipeline script to the working directory
#'
#' Writes the runnable, commented walkthrough shipped in the package's
#' `inst/scripts/` to the working directory, where it can be edited and sourced.
#' It takes a project from raw search-engine output through the annotation
#' table, the cached `pep_all` and on to rendered HTML reports, and every report
#' is produced with [run_howmahico_report()] rather than by opening a template
#' and knitting it by hand.
#'
#' The script starts in demo mode (`RUN_DEMO <- TRUE`): sourced as-is it runs end
#' to end against the simulated FragPipe dataset shipped in the package, so a
#' fresh install can be exercised before any real data is involved. Setting
#' `RUN_DEMO <- FALSE` switches it to the `CONFIG` block at the top.
#'
#' The sibling of [get_report_template()] (which copies a report skeleton) and
#' [get_dictionary_template()] (which copies the custom-parser dictionary).
#' `vignette("howmahico")` narrates the same walkthrough without running it.
#'
#' @param file Destination path for the copied script.
#' @param overwrite Logical; overwrite `file` if it already exists.
#'
#' @return The destination path, invisibly.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' get_pipeline_script("howmahico_pipeline.R")
#' # then open it, keep RUN_DEMO = TRUE, and source it to see a full run
#' }
get_pipeline_script <- function(file = "howmahico_pipeline.R",
                                overwrite = FALSE) {
  src <- system.file("scripts", "howmahico_pipeline.R", package = "HowMaHiCo")
  if (src == "") {
    stop("Pipeline script not found in the installed package.")
  }
  if (file.exists(file) && !overwrite) {
    stop("File already exists: ", file, ". Use overwrite = TRUE to replace it.")
  }
  file.copy(src, file, overwrite = overwrite)
  message("Pipeline script written to ", normalizePath(file))
  invisible(file)
}
