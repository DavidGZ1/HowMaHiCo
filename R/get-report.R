#' Get the HowMaHiCo templates
#'
#' This is a wrapper using rmarkdown::draft to get the HowMaHiCo templates template copied in the working directory
#'
#' @param file name of the report file to be copied.
#' @param template name of the template file to be used.
#' @param edit flag.
#' @param create_dir flag if directory should be created.
#'
#' @return None
#'
#' @examples
#' \dontrun{
#' get_report_template(file = "HowMaHiCoReportTemplate", template = "00_mhc_report", edit = TRUE, create_dir = FALSE)
#' }
#'
#' @export
get_report_template <- function(file = "HowMaHiCoReportTemplate", template = "00_mhc_report", edit = FALSE, create_dir = FALSE) {
  rmarkdown::draft(file = file,
                   template = template,
                   edit = edit,
                   package = "HowMaHiCo",
                   create_dir = create_dir)
}