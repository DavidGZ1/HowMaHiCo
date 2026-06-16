# Generic reader + annotator for the dictionary-driven "custom" software path.
# Mirrors the FragPipe batch reader's 3-way dispatch (files > annotation > scan),
# but with a configurable filename/delimiter so any per-sample-folder tabular
# export can be ingested. See R/parse-unified.R for the mapping engine and
# R/build-pep-all.R for the `software = "custom"` branch that wires them together.

#' Batch-read a generic per-sample tabular export
#'
#' Reads one delimited file per sample subfolder and row-binds the result,
#' tagging each row with `Sample_fp` (the subfolder name). The dictionary-driven
#' counterpart of [read_fragpipe_batch()] / [read_diann_batch()], with the
#' filename and delimiter taken from the dictionary's `read:` block instead of
#' being hard-coded. Three input modes are checked in priority order:
#'
#' 1. **`files`** — character vector of file paths or their parent folders;
#'    sample names are taken from the immediate parent folder.
#' 2. **`annotation`** — only `Sample_fp` entries listed in the annotation table
#'    are read from `folder`; warns about annotated samples not found on disk.
#' 3. **neither** — `folder` is scanned recursively for every file named `file`.
#'
#' @param folder Top-level directory. Required for the `annotation` and scan-all
#'   modes; unused when `files` is supplied.
#' @param annotation Optional annotation data frame (output of [read_annot()]).
#'   When provided without `files`, only its `Sample_fp` entries are read.
#' @param files Optional character vector of file paths or parent folder paths.
#' @param file Filename to read inside each sample subfolder (e.g. `"psm.tsv"`).
#' @param delim Field delimiter passed to [readr::read_delim()] (`"\t"` for tsv,
#'   `","` for csv).
#' @param testmode Logical; if `TRUE`, reads only the first ~100 rows per file.
#'
#' @return The merged raw data frame across every file found, with `Sample_fp`
#'   identifying the source subfolder of each row.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_custom_batch(folder = "2_data/my_export", annotation = annot,
#'                   file = "results.tsv", delim = "\t")
#' }
read_custom_batch <- function(folder = NULL, annotation = NULL, files = NULL,
                              file = "results.tsv", delim = "\t", testmode = FALSE) {
  read_one <- function(path, samplename) {
    n_max <- if (testmode) 100L else Inf
    readr::read_delim(path, delim = delim, show_col_types = FALSE,
                      progress = FALSE, n_max = n_max) |>
      dplyr::mutate(Sample_fp = samplename) |>
      dplyr::relocate(Sample_fp)
  }

  if (!is.null(files)) {
    file_paths   <- ifelse(endsWith(files, file), files, file.path(files, file))
    found        <- file.exists(file_paths)
    if (any(!found)) {
      warning("The following paths were not found and will be skipped:\n",
              paste(file_paths[!found], collapse = ", "))
    }
    file_paths   <- file_paths[found]
    sample_names <- basename(dirname(file_paths))
  } else if (!is.null(annotation)) {
    if (is.null(folder)) stop("'folder' must be provided when 'annotation' is supplied")
    sample_fps  <- unique(as.character(annotation$Sample_fp))
    file_paths  <- file.path(folder, sample_fps, file)
    missing     <- !file.exists(file_paths)
    if (any(missing)) {
      warning("The following annotated samples were not found on disk and will be skipped:\n",
              paste(sample_fps[missing], collapse = ", "))
    }
    file_paths   <- file_paths[!missing]
    sample_names <- sample_fps[!missing]
  } else {
    if (is.null(folder)) stop("'folder' must be provided when 'annotation' and 'files' are both NULL")
    all_files    <- list.files(folder, recursive = TRUE)
    hit          <- basename(all_files) == file
    file_paths   <- file.path(folder, all_files[hit])
    sample_names <- basename(dirname(file_paths))
  }

  raw_list <- lapply(seq_along(file_paths), function(i) {
    read_one(file_paths[i], sample_names[i])
  })
  do.call(dplyr::bind_rows, raw_list)
}

#' Join a dictionary-parsed table to the sample annotation
#'
#' The generic counterpart of [annotate_fragpipe()] for the custom path:
#' validates the annotation's minimal columns, warns about samples present on
#' only one side, and inner-joins on `Sample_fp` (`"individual_files"`) or
#' `Sample_fp` + `Source_file` (`"combined_file"`). Unlike [annotate_fragpipe()]
#' it relocates `Sample_ID` to the last column rather than after `Is_Unique`
#' (a generic export need not carry FragPipe's `Is_Unique` column).
#'
#' @param input Output of [parse_unified()].
#' @param annotation Annotation data frame; must contain at least `Condition`,
#'   `BioReplicate`, `TechReplicate`, `Sample`, `Sample_fp` (and `Source_file`
#'   when `mode = "combined_file"`).
#' @param mode `"individual_files"` (default) or `"combined_file"`.
#'
#' @return The inner join of `annotation` and `input`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' annotate_unified(parsed, annotation, mode = "individual_files")
#' }
annotate_unified <- function(input, annotation, mode = "individual_files") {
  minimal_columns <- c("Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_fp")
  miss <- setdiff(minimal_columns, names(annotation))
  if (length(miss)) {
    stop("The following columns are missing from the annotation table, please add them:\n",
         paste(miss, collapse = ", "))
  }

  key <- if (mode == "combined_file") c("Sample_fp", "Source_file") else "Sample_fp"
  if (mode == "combined_file" && !"Source_file" %in% names(annotation)) {
    stop("combined_file mode was activated, but the Source_file column is missing from the annotation table, please add it")
  }
  if (mode == "combined_file" && !"Source_file" %in% names(input)) {
    stop("combined_file mode requires the dictionary to map 'Source_file'.")
  }

  sample_keys <- function(df) {
    df |>
      dplyr::select(dplyr::all_of(key)) |>
      unique() |>
      dplyr::arrange(dplyr::across(dplyr::all_of(key))) |>
      tidyr::unite(col = "k", dplyr::all_of(key), sep = ",", remove = TRUE) |>
      dplyr::pull("k")
  }
  input_samples      <- sample_keys(input)
  annotation_samples <- sample_keys(annotation)

  if (all(input_samples %in% annotation_samples) &&
      all(annotation_samples %in% input_samples)) {
    message("All samples were correctly matched between the input results and the annotation table")
  }
  if (!all(input_samples %in% annotation_samples)) {
    warning("The following samples from the input results were not found in the annotation table and will be dropped:\n",
            paste(setdiff(input_samples, annotation_samples), collapse = "; "))
  }
  if (!all(annotation_samples %in% input_samples)) {
    warning("The following samples from the annotation table were not found in the input results and will be dropped:\n",
            paste(setdiff(annotation_samples, input_samples), collapse = "; "))
  }

  output <- dplyr::inner_join(annotation, input, by = key) |> droplevels()
  if ("Sample_ID" %in% names(output)) {
    output <- dplyr::relocate(output, "Sample_ID", .after = dplyr::last_col())
  }
  output
}
