#' Check whether a single output file already exists
#'
#' Throws an error if `file` already exists and `overwrite = FALSE`, or warns
#' (and proceeds) if it exists and `overwrite = TRUE`. Used as a pre-flight
#' guard before writing report outputs, so a re-render cannot silently
#' clobber a prior analysis run.
#'
#' @param file Path to the file to check, full path.
#' @param overwrite Logical; whether to allow overwriting an existing file.
#'
#' @return Invisible `NULL`; called for its side effects (`stop()`/`warning()`).
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' check_file_exists("3_results/all/pep_all.csv", overwrite = FALSE)
#' }
check_file_exists <- function(file, overwrite = FALSE){
  if(file.exists(file) & overwrite == TRUE){
    warning("The following file already exists and will be overwritten:")
    print(file)
  }
  if(file.exists(file) & overwrite == FALSE){
    stop("The following file already exists. Please rename, replace or remove the conflicting file")
    print(file)
  }
}

#' Check whether any of the report's standard output files already exist
#'
#' Looks for the full set of result files the report writes (`pep_all.csv`,
#' `seq_by_condition.xlsx`, the upset/overlap tables, etc.) inside `dir`, and
#' throws an error listing every match if any are found and `overwrite = FALSE`.
#' Complements [check_file_exists()] — checking the whole output set at once
#' makes it easier to surface every conflict in one pass rather than failing
#' partway through a render.
#'
#' @param dir Directory where the results should be stored.
#' @param overwrite Logical; whether to allow overwriting existing files.
#'
#' @return Invisible `NULL`; called for its side effects (`stop()`/`warning()`).
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' check_output_exists("3_results/all", overwrite = FALSE)
#' }
check_output_exists <- function(dir, overwrite = FALSE){
  res_files_found <-
    data.frame(res_file = c(file.path(dir, "seq_by_condition.xlsx"),
                            file.path(dir, "seq_by_workflow.xlsx"),
                            file.path(dir, "seq_overlap_condition.xlsx"),
                            file.path(dir, "seq_overlap_workflow.xlsx"),
                            file.path(dir, "pep_all.csv"),
                            file.path(dir, "summary_peaks.csv"),
                            file.path(dir, "upset_table_pep.csv"),
                            file.path(dir, "upset_table_prot.csv"),
                            file.path(dir, "upset_table_prot.csv"),
                            file.path(dir, "upset_table_unique.csv"),
                            file.path(dir, "pep_overlap.csv"))) %>%
    dplyr::mutate(found = file.exists(res_file)) %>%
    dplyr::filter(found)

  if(nrow(res_files_found) >= 1 & overwrite == FALSE){
    warning("The following result files were found and they cannot be overwritten.
            Please rename, replace or remove them before starting the code again")

    print(res_files_found)
    stop("Please rename, replace or remove the conflicting result files")
  }
}
