#' Read one FragPipe `psm.tsv`/DIA-NN `report.tsv` file
#'
#' Reads a single search-engine tsv with [readr::read_tsv()] (optionally
#' truncated to the first ~100 rows for fast iteration via `testmode`), and
#' tags every row with `samplename`. Shared by both the FragPipe and DIA-NN
#' batch readers — the two formats only diverge once the per-sample frames are
#' parsed into `pep_all` shape.
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
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' fp_read_psm("2_data/fragpipe_dda_combined/JY/psm.tsv", "JY", testmode = FALSE)
#' }
fp_read_psm <- function(folder, samplename, testmode = FALSE){
  if(testmode == TRUE){
    input <- readr::read_tsv(folder, show_col_types = FALSE, progress = FALSE, n_max = 100)
    warning("Test mode ON: only the first 50 lines were loaded")

  }else{
    input <- readr::read_tsv(folder, show_col_types = FALSE, progress = FALSE)
  }
  input %>%
    dplyr::mutate(Sample_fp = samplename) %>%
    dplyr::relocate(Sample_fp)
}

#' Batch-read every FragPipe `psm.tsv` under a folder and merge them
#'
#' Recursively lists `folder` for `psm.tsv` files, derives each one's sample
#' name from its parent subfolder, reads them all with [fp_read_psm()], and
#' row-binds the result.
#'
#' @param folder Top-level directory to search recursively for `psm.tsv` files.
#' @param testmode Logical; passed through to [fp_read_psm()] (loads only the
#'   first ~100 rows per file when `TRUE`, for fast iteration).
#'
#' @return The merged raw PSM data frame across every file found, with
#'   `Sample_fp` identifying the source subfolder of each row.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' fp_read_psm_batch(file.path("2_data", "fragpipe_dda_combined"), testmode = FALSE)
#' }
fp_read_psm_batch <- function(folder, testmode = FALSE){
  ## get index of files in the folder
  files_data_all <- list.files(folder, recursive = TRUE)

  files_data_psm <-
    file.path(folder, files_data_all[grepl("psm.tsv", files_data_all, fixed = TRUE)])
  ## get sample names
  sample_names <- stringr::str_match(files_data_psm, "[/]\\s*(.*?)\\s*[/]psm.tsv")[, 2]

  psm_raw_list <-
    lapply(c(1:length(files_data_psm)), function(x){
      fp_read_psm(file.path(files_data_psm[x]), sample_names[x], testmode = testmode)
    })
  psm_raw <- do.call(args = psm_raw_list, what = dplyr::bind_rows)
  return(psm_raw)
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
#' @param input Output of [fp_read_psm_batch()].
#' @param shortpep_range Length 2 vector `c(min, max)` defining the
#'   `Length_range` classification window (8-13 AAs for HLA-I).
#'
#' @return The input reshaped into `pep_all` long format.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' fp_parse_pep_all(fp_read_psm_batch(folder), shortpep_range = c(8, 13))
#' }
fp_parse_pep_all <- function(input, shortpep_range = c(8, 13)){
  ## reformat column names, create new ones, then use select to select, rename and reorder columns

  if(all(input$Intensity == 0)){
    warning("All Intensity (Area) values were 0. Log2Area will be inputed to 1 to avoid -Inf values")
  }

  input %>%
    dplyr::rename_with(~ gsub(patt = " ", rep = "_", .x), dplyr::everything()) %>%
    dplyr::rename_with(~ gsub(patt = "/", rep = ".", .x, fixed = TRUE), dplyr::everything()) %>%
    dplyr::mutate(
      Retention = Retention / 60, # in seconds in Fragpipe but in min in PEAKS
      Modified_Peptide = ifelse(is.na(Modified_Peptide), Peptide, Modified_Peptide), # Modified_Peptide is na if not modified
      PeptideID = paste0(Protein, "_", round(Calibrated_Observed_M.Z, 1), "_", as.numeric(Charge)),
      OrganismFirst = sub(".*_", "", Entry_Name),
      Log2Area = ifelse(Intensity == 0, 1, log2(Intensity)),
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
    ) %>%
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
    )
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
#' @param input Output of [fp_parse_pep_all()].
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
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' fp_annotate(pep_parsed, annotation, mode = "combined_file")
#' }
fp_annotate <- function(input, annotation, mode = "individual_files"){
  ## check if annotation table has all the information needed
  minimal_columns <- c("Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_fp")

  if(!all(minimal_columns %in% names(annotation))){
    stop(paste0("The following columns are missing from the annotation table, please add them:\n",
                paste0(minimal_columns[!minimal_columns %in% names(annotation)], collapse = ", ")))
  }
  ## throw a warning if some samples will be dropped
  ### need to use both Sample_fp and Source_file in case of multiple results per sample
  input_samples <-
    input %>%
    dplyr::select(Sample_fp, Source_file) %>%
    unique() %>%
    dplyr::arrange(Sample_fp, Source_file) %>%
    tidyr::unite(col = "Sample", Sample_fp, Source_file, sep = ",", remove = TRUE) %>%
    dplyr::pull(Sample)

  annotation_samples <-
    annotation %>%
    dplyr::select(Sample_fp, Source_file) %>%
    unique() %>%
    dplyr::arrange(Sample_fp, Source_file) %>%
    tidyr::unite(col = "Sample", Sample_fp, Source_file, sep = ",", remove = TRUE) %>%
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
      dplyr::inner_join(annotation, input, by = c("Sample_fp")) %>%
      dplyr::relocate(Sample_ID, .after = "Is_Unique")
  }
  if(mode == "combined_file"){
    ## check if annotation table contains Source_file
    if(!all(c("Source_file") %in% names(annotation))){
      stop("combined_file mode was activated, but the Source_file column is missing from the annotation table, please add it")
    }
    output <- input %>%
      dplyr::inner_join(annotation, ., by = c("Source_file", "Sample_fp")) %>%
      dplyr::relocate(Sample_ID, .after = "Is_Unique") %>%
      droplevels() # necessary to avoid dragging empty factors that create errors
  }
  return(output)
}
