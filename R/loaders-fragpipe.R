#' Read one FragPipe `psm.tsv` or DIA-NN `report.tsv` file
#'
#' Reads a single search-engine tsv with [readr::read_tsv()] (optionally
#' truncated to the first ~100 rows for fast iteration via `testmode`), and
#' tags every row with `samplename`. Shared internally by both the FragPipe and
#' DIA-NN batch readers — the two formats only diverge once the per-sample
#' frames are parsed into `pep_all` shape.
#'
#' @param folder Path to the tsv file to read.
#' @param samplename Sample identifier to record in the new `Sample_fp` column
#'   (derived from the file's parent folder name by the batch reader).
#' @param testmode Logical; if `TRUE`, reads only the first ~100 rows for fast
#'   iteration (can break downstream correlation plots on tiny subsets).
#'
#' @return The tsv contents as a data frame, with `Sample_fp` added and
#'   relocated to the first column.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_fragpipe("2_data/fragpipe_dda_combined/JY/psm.tsv", "JY", testmode = FALSE)
#' }
read_fragpipe <- function(folder, samplename, testmode = FALSE){
  if(testmode){
    input <- readr::read_tsv(folder, show_col_types = FALSE, progress = FALSE, n_max = 100)
    warning("Test mode ON: only the first 50 lines were loaded")

  }else{
    input <- readr::read_tsv(folder, show_col_types = FALSE, progress = FALSE)
  }
  input |>
    dplyr::mutate(Sample_fp = samplename) |>
    dplyr::relocate(Sample_fp)
}

#' Batch-read FragPipe `psm.tsv` files and merge them
#'
#' Reads all FragPipe `psm.tsv` files and row-binds the result. Three input
#' modes are supported (checked in priority order):
#'
#' 1. **`files`** — character vector of `psm.tsv` file paths or their parent
#'    folder paths; sample names are taken from the immediate parent folder.
#' 2. **`annotation`** — only the `Sample_fp` entries listed in the annotation
#'    table are read from `folder`; warns about any annotated samples not found
#'    on disk.
#' 3. **neither** — `folder` is scanned recursively for every `psm.tsv`
#'    (original default behaviour).
#'
#' @param folder Top-level directory. Required when using the `annotation` or
#'   scan-all modes; unused when `files` is supplied.
#' @param annotation Optional annotation data frame (output of [read_annot()]).
#'   When provided without `files`, only `Sample_fp` entries present in
#'   `annotation` are read.
#' @param files Optional character vector of `psm.tsv` file paths or parent
#'   folder paths to read directly.
#' @param testmode Logical; passed through to [read_fragpipe()] (loads only the
#'   first ~100 rows per file when `TRUE`, for fast iteration).
#'
#' @return The merged raw PSM data frame across every file found, with
#'   `Sample_fp` identifying the source subfolder of each row.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # scan entire folder
#' read_fragpipe_batch(file.path("2_data", "fragpipe_dda_combined"), testmode = FALSE)
#'
#' # restrict to annotated samples only
#' read_fragpipe_batch(folder = "2_data", annotation = annot)
#'
#' # provide paths explicitly
#' read_fragpipe_batch(files = c("2_data/fragpipe/JY_1/psm.tsv", "2_data/fragpipe/JY_2"))
#' }
read_fragpipe_batch <- function(folder = NULL, annotation = NULL, files = NULL,
                                testmode = FALSE){
  if (!is.null(files)) {
    file_paths <- ifelse(
      endsWith(files, "psm.tsv"), files,
      file.path(files, "psm.tsv")
    )
    found <- file.exists(file_paths)
    if (any(!found))
      warning("The following paths were not found and will be skipped:\n",
              paste(file_paths[!found], collapse = ", "))
    file_paths   <- file_paths[found]
    sample_names <- basename(dirname(file_paths))
  } else if (!is.null(annotation)) {
    if (is.null(folder)) stop("'folder' must be provided when 'annotation' is supplied")
    sample_fps <- unique(as.character(annotation$Sample_fp))
    file_paths  <- file.path(folder, sample_fps, "psm.tsv")
    missing     <- !file.exists(file_paths)
    if (any(missing))
      warning("The following annotated samples were not found on disk and will be skipped:\n",
              paste(sample_fps[missing], collapse = ", "))
    file_paths   <- file_paths[!missing]
    sample_names <- sample_fps[!missing]
  } else {
    if (is.null(folder)) stop("'folder' must be provided when 'annotation' and 'files' are both NULL")
    files_data_all <- list.files(folder, recursive = TRUE)
    file_paths   <- file.path(folder, files_data_all[grepl("psm.tsv", files_data_all, fixed = TRUE)])
    sample_names <- stringr::str_match(file_paths, "[/]\\s*(.*?)\\s*[/]psm.tsv")[, 2]
  }

  psm_raw_list <- lapply(seq_along(file_paths), function(x){
    read_fragpipe(file_paths[x], sample_names[x], testmode = testmode)
  })
  do.call(args = psm_raw_list, what = dplyr::bind_rows)
}

#' Parse raw FragPipe PSM results into `pep_all` format
#'
#' Reformats column names, derives the shared `pep_all` columns (`PeptideID`,
#' `Log2Area`, `Length_range`, `Nter`/`Cter`, `ppm`, `Source_file`, ...), and
#' selects/renames/reorders columns to converge on the unified schema shared
#' with the DIA-NN and PEAKS loaders.
#'
#' Note FragPipe results are read at the **PSM level**, not the peptide level
#' — FDR is therefore applied only at the PSM level here; treat downstream
#' FragPipe peptide counts with that caveat in mind.
#'
#' @param input Output of [read_fragpipe_batch()].
#' @param shortpep_range Length 2 vector `c(min, max)` defining the
#'   `Length_range` classification window (8-13 AAs for HLA-I).
#'
#' @return The input reshaped into `pep_all` long format.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' parse_fragpipe(read_fragpipe_batch(folder), shortpep_range = c(8, 13))
#' }
parse_fragpipe <- function(input, shortpep_range = c(8, 13)){
  ## reformat column names, create new ones, then use select to select, rename and reorder columns

  if(all(input$Intensity == 0)){
    warning("All Intensity (Area) values were 0. Log2Area will be NA for those rows (a zero Area has no defined log2)")
  }

  input |>
    dplyr::rename_with(~ gsub(patt = " ", rep = "_", .x), dplyr::everything()) |>
    dplyr::rename_with(~ gsub(patt = "/", rep = ".", .x, fixed = TRUE), dplyr::everything()) |>
    dplyr::mutate(
      Retention = Retention / 60, # in seconds in Fragpipe but in min in PEAKS
      Modified_Peptide = ifelse(is.na(Modified_Peptide), Peptide, Modified_Peptide), # Modified_Peptide is na if not modified
      PeptideID = paste0(Protein, "_", round(Calibrated_Observed_M.Z, 1), "_", as.numeric(Charge)),
      OrganismFirst = sub(".*_", "", Entry_Name),
      Log2Area = compute_log2area(Intensity),
      Charge = as.factor(paste0("+ ", Charge)),
      Length_range = dplyr::case_when(Peptide_Length >= shortpep_range[1] & Peptide_Length <= shortpep_range[2] ~
                                        paste0(shortpep_range[1], " to ", shortpep_range[2], " AAs"),
                                      Peptide_Length < shortpep_range[1] | Peptide_Length > shortpep_range[2] ~ "others"),
      Length_range = factor(Length_range),
      Nter = as.factor(stringr::str_sub(Peptide, 1, 1)),
      Cter = as.factor(stringr::str_sub(Peptide, -1, -1)),
      ppm = 1E6 * ((Calibrated_Observed_M.Z - Calculated_M.Z) / Calculated_M.Z),
      Found_By = "FragPipe",
      Source_file = sub("[.].*", "", Spectrum),
      Source_file = sub("_diatracer", "", Source_file) # faciliate merging when dda+dia worklfow was used
    ) |>
    dplyr::select(Sample_fp,
                  Accession = Protein,
                  Peptide = Modified_Peptide,
                  Sequence = Peptide,
                  Length = Peptide_Length,
                  Score = Hyperscore,
                  Area = Intensity,
                  Log2Area,
                  Length_range,
                  PTM = Assigned_Modifications,
                  Charge,
                  Nter,
                  Cter,
                  RT = Retention,
                  invk0 = Ion_Mobility,
                  Mass = Calibrated_Observed_Mass,
                  ppm,
                  m_z = Calibrated_Observed_M.Z,
                  Source_file,
                  Source_File_ID = Spectrum_File,
                  Precursor_Id = Spectrum,
                  Found_By,
                  PeptideID,
                  ProteinFirst = Protein_ID,
                  GeneFirst = Gene,
                  OrganismFirst,
                  Nextscore,
                  Probability,
                  Qvalue,
                  Protein_Description,
                  Mapped_Genes,
                  Mapped_Proteins,
                  Is_Decoy,
                  Is_Contaminant,
                  Is_Unique
    ) |>
    validate_pep_all("FragPipe")
}

#' Join parsed FragPipe results to the sample annotation table
#'
#' Validates that the annotation table has the minimal required columns,
#' compares the (`Sample_fp`, `Source_file`) pairs found in `input` vs.
#' `annotation` and warns about any that will be dropped on either side, then
#' inner-joins on the matching key appropriate for `mode` — `Sample_fp` alone
#' for `"individual_files"`, or `Sample_fp` + `Source_file` for
#' `"combined_file"` (FragPipe combined PSM).
#'
#' @param input Output of [parse_fragpipe()].
#' @param annotation Annotation data frame; must contain at least `Condition`,
#'   `BioReplicate`, `TechReplicate`, `Sample`, `Sample_fp` (and `Source_file`
#'   when `mode = "combined_file"`).
#' @param mode One of `"individual_files"` (one folder per file, matched on
#'   `Sample_fp`) or `"combined_file"` (combined PSM, matched on `Sample_fp` +
#'   `Source_file`).
#'
#' @return The inner join of `annotation` and `input`, with `Sample_ID`
#'   relocated to the end and (for `"combined_file"` mode) empty factor levels
#'   dropped.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' annotate_fragpipe(pep_parsed, annotation, mode = "combined_file")
#' }
annotate_fragpipe <- function(input, annotation, mode = "individual_files"){
  ## check if annotation table has all the information needed
  minimal_columns <- c("Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_fp")

  if(!all(minimal_columns %in% names(annotation))){
    stop(paste0("The following columns are missing from the annotation table, please add them:\n",
                paste0(minimal_columns[!minimal_columns %in% names(annotation)], collapse = ", ")))
  }
  ## throw a warning if some samples will be dropped
  ### need to use both Sample_fp and Source_file in case of multiple results per sample
  input_samples <-
    input |>
    dplyr::select(Sample_fp, Source_file) |>
    unique() |>
    dplyr::arrange(Sample_fp, Source_file) |>
    tidyr::unite(col = "Sample", Sample_fp, Source_file, sep = ",", remove = TRUE) |>
    dplyr::pull(Sample)

  annotation_samples <-
    annotation |>
    dplyr::select(Sample_fp, Source_file) |>
    unique() |>
    dplyr::arrange(Sample_fp, Source_file) |>
    tidyr::unite(col = "Sample", Sample_fp, Source_file, sep = ",", remove = TRUE) |>
    dplyr::pull(Sample)
  if(all(input_samples %in% annotation_samples) & all(annotation_samples %in% input_samples)){
    message("All samples were correctly matched between the input results and the annotation table")
  }

  if(!all(input_samples %in% annotation_samples)){
    warning(paste0("The following samples from the input results were not found in the annotation table and will be dropped:\n",
                   paste0(input_samples[!input_samples %in% annotation_samples], collapse = "; ")))
  }
  if(!all(annotation_samples %in% input_samples)){
    warning(paste0("The following samples (Sample_fp,Source_file) from the annotation table were not found in the input results and will be dropped:\n",
                   paste0(annotation_samples[!annotation_samples %in% input_samples], collapse = ", ")))
  }
  if(!all(input_samples %in% annotation_samples)){
    warning(paste0("The following samples (Sample_fp,Source_file) from the input results were not found in the annotation table  and will be dropped:\n",
                   paste0(annotation_samples[!annotation_samples %in% input_samples], collapse = ", ")))
  }
  ## merge
  if(mode == "individual_files") {
    output <-
      dplyr::inner_join(annotation, input, by = c("Sample_fp")) |>
      dplyr::relocate(Sample_ID, .after = "Is_Unique")
  }
  if(mode == "combined_file"){
    ## check if annotation table contains Source_file
    if(!all(c("Source_file") %in% names(annotation))){
      stop("combined_file mode was activated, but the Source_file column is missing from the annotation table, please add it")
    }
    output <- input |>
      (\(x) dplyr::inner_join(annotation, x, by = c("Source_file", "Sample_fp")))() |>
      dplyr::relocate(Sample_ID, .after = "Is_Unique") |>
      droplevels() # necessary to avoid dragging empty factors that create errors
  }
  return(output)
}
