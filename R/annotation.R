#' Read, validate, and reformat a sample annotation table
#'
#' Reads the annotation csv, strips `.d`/`.raw` extensions from `Source_file`
#' (if present), checks that the required columns are present, harmonizes the
#' data-folder column across search engines (see below), normalizes
#' `Sample_peaks` to match PEAKS' own export-naming behavior (hyphens/spaces
#' replaced by underscores), and sets factor levels for every character column
#' from the row order in the csv — this is what gives downstream plots/tables
#' their condition/sample ordering.
#'
#' **One annotation format for every software.** The column naming the data
#' subfolder of each sample is `Sample_folder`, whatever the search engine. The
#' historical, engine-specific names are still accepted: a table providing
#' `Sample_fp` (FragPipe/DIA-NN/custom) or `Sample_peaks` (PEAKS) loads
#' unchanged. Whichever is present, the others are derived: `Sample_fp` is a
#' verbatim copy of `Sample_folder`, and `Sample_peaks` is a copy with PEAKS'
#' hyphen/space normalization applied — so the loaders, which key on
#' `Sample_fp`/`Sample_peaks`, keep working either way. A column the user
#' supplied is never overwritten.
#'
#' @param file_annot Path to a csv file with the annotation table, including at
#'   least the columns `Condition`, `BioReplicate`, `TechReplicate`, `Sample`,
#'   and one of `Sample_folder` (preferred) / `Sample_fp` / `Sample_peaks`.
#'
#' @return The annotation data frame, with `Source_file` extensions stripped,
#'   `Sample_folder`/`Sample_fp`/`Sample_peaks` all populated (`Sample_peaks`
#'   with hyphens/spaces normalized to underscores), and every character column
#'   converted to a factor ordered by first appearance.
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
  folder_cols <- c("Sample_folder", "Sample_fp", "Sample_peaks")
  if(!any(folder_cols %in% names(annot))){
    stop("The annotation table must contain a Sample_folder column (or the legacy ",
         "Sample_fp / Sample_peaks), please add it and try again")
  }
  if(!all(c("Condition", "BioReplicate", "TechReplicate", "Sample") %in% names(annot))){
    stop("The annotation table must contain all the following columns, please add those ones missing and try again.
         Condition, BioReplicate, TechReplicate, Sample")
  }

  # harmonize the data-folder column across software: Sample_folder is canonical,
  # Sample_fp/Sample_peaks are the loader-facing aliases derived from it (an
  # explicitly supplied alias is kept as-is)
  if(!"Sample_folder" %in% names(annot)){
    source_col <- if("Sample_fp" %in% names(annot)) "Sample_fp" else "Sample_peaks"
    annot$Sample_folder <- as.character(annot[[source_col]])
  }
  annot$Sample_folder <- as.character(annot$Sample_folder)
  if(!"Sample_fp" %in% names(annot))    annot$Sample_fp <- annot$Sample_folder
  if(!"Sample_peaks" %in% names(annot)) annot$Sample_peaks <- annot$Sample_folder
  annot <- annot |> dplyr::relocate(Sample_folder, .before = "Sample_fp")

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
#' @return A data frame with columns `Source_file`, `Sample_folder`,
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
    dplyr::rename(Source_file = values, Sample_folder = ind) |>
    dplyr::mutate(Sample_folder = gsub("/psm.tsv", "", Sample_folder, fixed = TRUE)) |>
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
#' @return A data frame with columns `Source_file`, `Sample_folder`,
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
    dplyr::rename(Source_file = values, Sample_folder = ind) |>
    dplyr::mutate(Sample_folder = gsub("/report.tsv", "", Sample_folder, fixed = TRUE)) |>
    dplyr::mutate(Condition = "", BioReplicate = "", TechReplicate = "", Sample = "", Sample_ID = "") |>
    dplyr::arrange(Source_file)
}

#' Auto-generate a skeleton annotation table from a PEAKS export folder
#'
#' PEAKS counterpart of [get_annot_fragpipe()] / [get_annot_diann()]: indexes the
#' search-result subfolders of a PEAKS export with the same internal indexer
#' [read_peaks_batch()] uses to pick folders, drops the QC folders, and returns
#' one row per result folder ready to fill in.
#'
#' **One row per folder is not necessarily one row per sample.** A PEAKS export
#' folder usually holds several samples, one `Area#<sample>` column each inside
#' its `peptide.csv`, and it is those suffixes that [annotate_peaks()] joins on.
#' So for a multi-sample export, duplicate the folder's row once per sample and
#' add a `Sample_peaks` column naming each sample exactly as its `Area#` column
#' does; `Sample_folder` stays the same on every one of those rows. With one
#' folder per sample the two keys coincide and [read_annot()] derives
#' `Sample_peaks` for you.
#'
#' @param dir_data Path to the PEAKS export root folder (the one holding the
#'   `<project>_PEAKS_<nn>` result subfolders).
#' @param drop_qc Drop the `_QC_` folders (default `TRUE`) — they are not sample
#'   results and [read_peaks_batch()] ignores them too.
#'
#' @return A data frame with columns `Sample_folder`, `File_peaks_nb`,
#'   `Condition`, `BioReplicate`, `TechReplicate`, `Sample`, `Sample_ID`,
#'   sorted by `Sample_folder`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' get_annot_peaks("2_data/peaks_export")
#' }
get_annot_peaks <- function(dir_data, drop_qc = TRUE){
  index <- get_dirs_index_peaks(dir_data)
  if (drop_qc) index <- index[!index$QC, , drop = FALSE]
  if (nrow(index) == 0)
    warning("get_annot_peaks(): no PEAKS result folder found under '", dir_data, "'")

  data.frame(Sample_folder = basename(index$path_full),
             File_peaks_nb = index$File_peaks_nb,
             Condition = "", BioReplicate = "", TechReplicate = "",
             Sample = "", Sample_ID = "",
             stringsAsFactors = FALSE) |>
    unique() |>
    dplyr::arrange(Sample_folder)
}

#' Enrich an annotation table with Sample_ID from a Bruker HyStar sample list
#'
#' Reads a Bruker HyStar sample list (xlsx), extracts `Result.Path` and
#' `Sample.Comment`, derives the run name from the path, and joins it to the
#' annotation table on `Source_file`, replacing any existing `Sample_ID`.
#'
#' The join is easy to get silently wrong — the two sides must agree on the run
#' naming, and with the default inner join a mismatch simply removes rows. This
#' function therefore warns when nothing matched (showing example values from
#' both sides) and when only some rows matched (naming the ones dropped);
#' `keep_all = TRUE` switches to a left join so no annotation row is ever lost.
#'
#' @param annotation Annotation data frame (e.g. from [get_annot_fragpipe()]
#'   or [read_annot()]).
#' @param file_sample_list Path to the Bruker HyStar sample list `.xlsx` file.
#' @param keep_all Keep every annotation row (left join, unmatched `Sample_ID`
#'   left `NA`) instead of dropping the unmatched ones. Default `FALSE`, the
#'   historical inner-join behaviour.
#'
#' @return `annotation` with the `Sample_ID` column filled from
#'   `Sample.Comment` in the sample list. Rows without a match are dropped
#'   (inner join) unless `keep_all = TRUE`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' annot <- get_annot_fragpipe("2_data")
#' get_annot_sampleid(annot, "1_documentation/sample_list.xlsx")
#' }
get_annot_sampleid <- function(annotation, file_sample_list, keep_all = FALSE){
  sample_list_all <- openxlsx::read.xlsx(file_sample_list, sheet = 1)
  sample_list_simple <-
    sample_list_all |>
    dplyr::select(Source_file = Result.Path, Sample_ID = Sample.Comment) |>
    dplyr::mutate(Source_file = extract_run_name(Source_file))

  annot_runs  <- as.character(annotation$Source_file)
  list_runs   <- as.character(sample_list_simple$Source_file)
  matched     <- annot_runs %in% list_runs
  examples    <- function(x) paste(utils::head(unique(x[!is.na(x)]), 3), collapse = ", ")

  if (!any(matched)) {
    warning("get_annot_sampleid(): no Source_file matched the sample list, so ",
            if (keep_all) "every Sample_ID stays empty.
" else "the result is empty.
",
            "  annotation Source_file (", length(unique(annot_runs)), "): ", examples(annot_runs), "
",
            "  sample list Source_file (", length(unique(list_runs)), "): ", examples(list_runs), "
",
            "  Check that both sides use the same run naming.", call. = FALSE)
  } else if (!all(matched)) {
    warning("get_annot_sampleid(): ", sum(!matched), " of ", length(matched),
            " annotation rows had no match in the sample list and were ",
            if (keep_all) "kept with an empty Sample_ID" else "dropped", ": ",
            examples(annot_runs[!matched]),
            if (sum(!matched) > 3) ", ..." else "", call. = FALSE)
  }

  join_fun <- if (keep_all) dplyr::left_join else dplyr::inner_join
  join_fun(dplyr::select(annotation, -Sample_ID), sample_list_simple, by = "Source_file")
}
