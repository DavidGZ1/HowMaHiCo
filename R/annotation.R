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
#' @export
#'
#' @examples
#' \dontrun{
#' read_annot(file.path("1_documentation", params$AnnotationFile))
#' }
read_annot <- function(file_annot){
  annot <- read.csv(file_annot) |>
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
      annot <- annot |> dplyr::mutate(Sample_peaks = gsub("-", "_", Sample_peaks))
      warning(" Hyphens ('-') in column Sample_peaks were replaced by underscores '_'
    as this is also done when exporting from PEAKS")
    }
    if(any(grepl(" ", annot$Sample_peaks))){
      annot <- annot |> dplyr::mutate(Sample_peaks = gsub(" ", "_", Sample_peaks))
      warning("Spaces (' ') in column Sample_peaks were replaced by underscores '_'
    as this is also done when exporting from PEAKS")
    }
  }
  # establish factor order with order from annot
  annot <- annot |>
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
#' @export
#'
#' @examples
#' \dontrun{
#' print_annot(read_annot(file.path("1_documentation", params$AnnotationFile)))
#' }
print_annot <- function(input){
  input |>
    DT::datatable(filter = "top",
                  rownames = FALSE,
                  escape = FALSE, # needed for html link and widgets rendering
                  extensions = c('FixedHeader'),
                  options = list(pageLength = 10,
                                 autoWidth = TRUE,
                                 scientific = TRUE,
                                 fixedHeader = TRUE))
}

#' Auto-generate a skeleton annotation table from FragPipe psm.tsv files
#'
#' Scans `dir_data` recursively for `psm.tsv` files, reads the `Spectrum`
#' column from each to derive unique `Source_file` names, and returns a
#' data frame with one row per source file ready to fill in
#' (`Condition`, `BioReplicate`, `TechReplicate`, `Sample`, `Sample_ID`
#' are left blank).
#'
#' @param dir_data Path to the root data folder containing FragPipe output
#'   subfolders (each with a `psm.tsv`).
#'
#' @return A data frame with columns `Source_file`, `Sample_fp`,
#'   `Condition`, `BioReplicate`, `TechReplicate`, `Sample`, `Sample_ID`,
#'   sorted by `Source_file`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' get_annot_fragpipe("2_data")
#' }
get_annot_fragpipe <- function(dir_data){
  data_files <- list.files(dir_data, recursive = TRUE)
  psm_files <- data_files[grepl("psm.tsv", data_files)]
  output_list <-
    sapply(psm_files, USE.NAMES = TRUE, simplify = FALSE, function(x){
      input <- paste0(dir_data, "/", x)
      readr::read_tsv(input, col_select = "Spectrum", show_col_types = FALSE, progress = FALSE) |>
        dplyr::mutate(Source_file = sub("[.].*", "", Spectrum)) |>
        dplyr::pull(Source_file) |>
        unique()
    })
  stack(output_list) |>
    dplyr::rename(Source_file = values, Sample_fp = ind) |>
    dplyr::mutate(Sample_fp = gsub("/psm.tsv", "", Sample_fp, fixed = TRUE)) |>
    dplyr::mutate(Source_file = gsub("_diatracer", "", Source_file, fixed = TRUE)) |>
    dplyr::mutate(Condition = "", BioReplicate = "", TechReplicate = "", Sample = "", Sample_ID = "") |>
    dplyr::arrange(Source_file)
}

#' Auto-generate a skeleton annotation table from DIA-NN report.tsv files
#'
#' Scans `dir_data` recursively for `report.tsv` files, reads the `Run`
#' column from each to derive unique `Source_file` names, and returns a
#' data frame with one row per source file ready to fill in.
#'
#' @param dir_data Path to the root data folder containing DIA-NN output
#'   subfolders (each with a `report.tsv`).
#'
#' @return A data frame with columns `Source_file`, `Sample_fp`,
#'   `Condition`, `BioReplicate`, `TechReplicate`, `Sample`, `Sample_ID`,
#'   sorted by `Source_file`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' get_annot_diann("2_data")
#' }
get_annot_diann <- function(dir_data){
  data_files <- list.files(dir_data, recursive = TRUE)
  diann_files <- data_files[grepl("report.tsv", data_files)]
  output_list <- sapply(diann_files, USE.NAMES = TRUE, simplify = FALSE, function(x){
    input <- paste0(dir_data, "/", x)
    readr::read_tsv(input, col_select = "Run", show_col_types = FALSE, progress = FALSE) |>
      dplyr::rename(Source_file = Run) |>
      dplyr::pull(Source_file) |>
      unique()
  })
  stack(output_list) |>
    dplyr::rename(Source_file = values, Sample_fp = ind) |>
    dplyr::mutate(Sample_fp = gsub("/report.tsv", "", Sample_fp, fixed = TRUE)) |>
    dplyr::mutate(Condition = "", BioReplicate = "", TechReplicate = "", Sample = "", Sample_ID = "") |>
    dplyr::arrange(Source_file)
}

#' Enrich an annotation table with Sample_ID from a Bruker HyStar sample list
#'
#' Reads a Bruker HyStar sample list (xlsx), extracts `Result.Path` and
#' `Sample.Comment`, derives the run name from the path, and inner-joins to
#' the annotation table on `Source_file`, replacing any existing `Sample_ID`.
#'
#' @param annotation Annotation data frame (e.g. from [get_annot_fragpipe()]
#'   or [read_annot()]).
#' @param file_sample_list Path to the Bruker HyStar sample list `.xlsx` file.
#'
#' @return `annotation` with the `Sample_ID` column filled from
#'   `Sample.Comment` in the sample list. Rows without a match are dropped
#'   (inner join).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' annot <- get_annot_fragpipe("2_data")
#' get_annot_sampleid(annot, "1_documentation/sample_list.xlsx")
#' }
get_annot_sampleid <- function(annotation, file_sample_list){
  sample_list_all <- openxlsx::read.xlsx(file_sample_list, sheet = 1)
  sample_list_simple <-
    sample_list_all |>
    dplyr::select(Source_file = Result.Path, Sample_ID = Sample.Comment) |>
    dplyr::mutate(Source_file = extract_run_name(Source_file))

  dplyr::inner_join(dplyr::select(annotation, -Sample_ID),
                    sample_list_simple, by = "Source_file")
}
