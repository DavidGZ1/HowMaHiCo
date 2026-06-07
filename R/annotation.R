#' Read, validate, and reformat a sample annotation table
#'
#' Reads the annotation csv, strips `.d`/`.raw` extensions from `Source_file`
#' (if present), checks that the required columns are present, normalizes
#' `Sample_peaks` to match PEAKS' own export-naming behavior (hyphens/spaces
#' replaced by underscores), and sets factor levels for every character column
#' from the row order in the csv — this is what gives downstream plots/tables
#' their condition/sample ordering.
#'
#' @param file_annot Path to a csv file with the annotation table, including at
#'   least the columns `Condition`, `BioReplicate`, `TechReplicate`, `Sample`,
#'   and one of `Sample_fp`/`Sample_peaks`.
#'
#' @return The annotation data frame, with `Source_file` extensions stripped,
#'   `Sample_peaks` hyphens/spaces normalized to underscores, and every
#'   character column converted to a factor ordered by first appearance.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' read_annot(file.path("1_documentation", params$AnnotationFile))
#' }
read_annot <- function(file_annot){
  annot <- read.csv(file_annot) %>%
    dplyr::mutate(dplyr::across(dplyr::any_of("Source_file"), ~ gsub(".d|.raw", "", .x)))

  # check that it table contains the columns needed
  if(!any(c("Sample_fp", "Sample_peaks") %in% names(annot))){
    stop("The annotation table must contain Sample_peaks or Sample_fp column, please add it and try again")
  }
  if(!all(c("Condition", "BioReplicate", "TechReplicate", "Sample") %in% names(annot))){
    stop("The annotation table must contain all the following columns, please add those ones missing and try again.
         Condition, BioReplicate, TechReplicate, Sample")
  }
  # rename Sample_peaks if necessary
  if("Sample_peaks" %in% names(annot)){
    if(any(grepl("-", annot$Sample_peaks))){
      annot <- annot %>% dplyr::mutate(Sample_peaks = gsub("-", "_", Sample_peaks))
      warning(" Hyphens ('-') in column Sample_peaks were replaced by underscores '_'
    as this is also done when exporting from PEAKS")
    }
    if(any(grepl(" ", annot$Sample_peaks))){
      annot <- annot %>% dplyr::mutate(Sample_peaks = gsub(" ", "_", Sample_peaks))
      warning("Spaces (' ') in column Sample_peaks were replaced by underscores '_'
    as this is also done when exporting from PEAKS")
    }
  }
  # establish factor order with order from annot
  annot <- annot %>%
    dplyr::mutate(dplyr::across(dplyr::where(is.character), function(x) factor(x, levels = unique(x))))
  return(annot)
}

#' Render an annotation table as an interactive HTML datatable
#'
#' Thin wrapper around [DT::datatable()] with the report's standard display
#' options (top filters, fixed header, no rownames).
#'
#' @param input Annotation data frame, typically the output of [read_annot()].
#'
#' @return A `DT::datatable` htmlwidget.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' print_annot(read_annot(file.path("1_documentation", params$AnnotationFile)))
#' }
print_annot <- function(input){
  input %>%
    DT::datatable(filter = "top",
                  rownames = FALSE,
                  escape = FALSE, # needed for html link and widgets rendering
                  extensions = c('FixedHeader'),
                  options = list(pageLength = 10,
                                 autoWidth = TRUE,
                                 scientific = TRUE,
                                 fixedHeader = TRUE))
}
