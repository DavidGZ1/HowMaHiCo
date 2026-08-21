#' Copy the custom-parser dictionary template to the working directory
#'
#' Writes the fill-in YAML dictionary template (shipped in the package's
#' `inst/extdata/dictionaries/`) to the working directory so it can be edited to
#' describe a new tabular search-engine export. The sibling of
#' [get_report_template()] for the dictionary-driven `software = "custom"` path
#' (see [parse_unified()] and [build_pep_all()]).
#'
#' @param file Destination path for the copied template.
#' @param overwrite Logical; overwrite `file` if it already exists.
#'
#' @return The destination path, invisibly.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' get_dictionary_template("my_tool.yaml")
#' # edit my_tool.yaml, then:
#' build_pep_all("custom", folder_data = "2_data", annotation = annot,
#'               dictionary = "my_tool.yaml", file_rda = "2_data/pep_all.rda")
#' }
get_dictionary_template <- function(file = "howmahico_dictionary.yaml",
                                    overwrite = FALSE) {
  src <- system.file("extdata", "dictionaries", "custom_template.yaml",
                     package = "HowMaHiCo")
  if (src == "") {
    stop("Dictionary template not found in the installed package.")
  }
  if (file.exists(file) && !overwrite) {
    stop("File already exists: ", file, ". Use overwrite = TRUE to replace it.")
  }
  file.copy(src, file, overwrite = overwrite)
  message("Dictionary template written to ", normalizePath(file))
  invisible(file)
}
