#' Batch-read every DIA-NN `report.tsv` under a folder and merge them
#'
#' Recursively lists `folder` for `report.tsv` files, derives each one's
#' sample name from its parent subfolder, reads them all with
#' [fp_read_psm()] (the same generic tsv reader used by the FragPipe loader —
#' the two formats only diverge once parsed into `pep_all` shape), and
#' row-binds the result.
#'
#' @param folder Top-level directory to search recursively for `report.tsv`
#'   files.
#' @param testmode Logical; passed through to [fp_read_psm()] (loads only the
#'   first ~100 rows per file when `TRUE`, for fast iteration).
#'
#' @return The merged raw DIA-NN report data frame across every file found,
#'   with `Sample_fp` identifying the source subfolder of each row.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' diann_read_tsv_batch(file.path("2_data", "diann"), testmode = FALSE)
#' }
diann_read_tsv_batch <- function(folder, testmode = FALSE){
  ## get index of files in the folder
  files_data_all <- list.files(folder, recursive = TRUE)

  files_data_psm <-
    file.path(folder, files_data_all[grepl("report.tsv", files_data_all, fixed = TRUE)])
  ## get sample names
  sample_names <- stringr::str_match(files_data_psm, "[/]\\s*(.*?)\\s*[/]report.tsv")[, 2]

  psm_raw_list <-
    lapply(c(1:length(files_data_psm)), function(x){
      fp_read_psm(file.path(files_data_psm[x]), sample_names[x], testmode = testmode)
    })
  psm_raw <- do.call(args = psm_raw_list, what = dplyr::bind_rows)
  return(psm_raw)
}

#' Parse raw DIA-NN report results into `pep_all` format
#'
#' Reformats column names, derives the shared `pep_all` columns (`PeptideID`,
#' `Log2Area`, `Length_range`, `Nter`/`Cter`, `Mass`, `Source_file`, ...), and
#' selects/renames/reorders columns to converge on the unified schema shared
#' with the FragPipe and PEAKS loaders.
#'
#' Two columns are not directly reported by DIA-NN: `ppm` is a hardcoded dummy
#' (`= 0`, since DIA-NN reports no calculated m/z to derive a mass error from);
#' `Mass` *is* computed here (from `Precursor.Mz`/`Precursor.Charge` via the
#' standard mass formula) but is **not** the calibrated/observed mass the
#' other loaders report — check this function directly if precision matters.
#'
#' @param input Output of [diann_read_tsv_batch()].
#' @param shortpep_range Length 2 vector `c(min, max)` defining the
#'   `Length_range` classification window (8-13 AAs for HLA-I).
#'
#' @return The input reshaped into `pep_all` long format.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' diann_parse_pep_all(diann_read_tsv_batch(folder), shortpep_range = c(8, 13))
#' }
diann_parse_pep_all <- function(input, shortpep_range = c(8, 13)){
  # mass and ppm not calculated
  input %>%
    dplyr::rename_with(~ gsub(patt = " ", rep = ".", .x), dplyr::everything()) %>%
    dplyr::mutate(
      PeptideID = paste0(All.Mapped.Proteins, "_", round(Precursor.Mz, 1), "_", as.numeric(Precursor.Charge)),
      OrganismFirst = gsub(".*_(.+).*", "\\1", All.Mapped.Proteins),
      Log2Area = ifelse(Ms1.Area == 0, 1, log2(Ms1.Area)),
      Charge = as.factor(paste0("+ ", Precursor.Charge)),
      PTM = apply(stringr::str_extract_all(Modified.Sequence, "\\([^()]+\\)", simplify = TRUE),
                  1,
                  function(row) paste(row[nzchar(row)], collapse = ", ")),
      Length = nchar(Stripped.Sequence),
      Length_range = dplyr::case_when(Length >= shortpep_range[1] & Length <= shortpep_range[2] ~
                                        paste0(shortpep_range[1], " to ", shortpep_range[2], " AAs"),
                                      Length < shortpep_range[1] | Length > shortpep_range[2] ~ "others"),
      Length_range = factor(Length_range),
      Nter = as.factor(stringr::str_sub(Stripped.Sequence, 1, 1)),
      Cter = as.factor(stringr::str_sub(Stripped.Sequence, -1, -1)),
      Mass = ((Precursor.Mz - 1.007276) * Precursor.Charge),
      ppm = 0, # DIA-NN does not give a calculated mz
      Source_file = gsub(".*\\\\(.+)[.].*", "\\1", File.Name),
      Found_By = "DIA-NN"
    ) %>%
    dplyr::select(Sample_fp,
                  Accession = All.Mapped.Proteins,
                  Peptide = Modified.Sequence,
                  Sequence = Stripped.Sequence,
                  Length,
                  Score = Q.Value,
                  Area = Ms1.Area,
                  Log2Area,
                  Length_range,
                  PTM,
                  Charge,
                  Nter,
                  Cter,
                  RT = RT,
                  invk0 = IM,
                  Mass,
                  ppm,
                  m_z = Precursor.Mz,
                  Sample_fp,
                  Source_file,
                  Source_File_ID = Run,
                  Precursor_Id = Precursor.Id,
                  Found_By,
                  PeptideID,
                  ProteinFirst = Protein.Group,
                  GeneFirst = Genes,
                  OrganismFirst,
                  Area_MS2 = Precursor.Normalised,
                  Protein.Ids,
                  Protein.Names,
                  PG.Quantity,
                  PG.Normalised,
                  PG.MaxLFQ,
                  Genes.Quantity,
                  Genes.Normalised,
                  Genes.MaxLFQ,
                  Genes.MaxLFQ.Unique,
                  PEP,
                  Global.Q.Value,
                  Protein.Q.Value,
                  PG.Q.Value,
                  Global.PG.Q.Value,
                  GG.Q.Value,
                  Translated.Q.Value,
                  Proteotypic,
                  Precursor.Quantity,
                  Precursor.Translated,
                  Translated.Quality,
                  Ms1.Translated,
                  Quantity.Quality,
                  iRT,
                  RT.Start,
                  RT.Stop,
                  Predicted.RT,
                  Predicted.iRT,
                  Lib.Q.Value,
                  Lib.PG.Q.Value,
                  Ms1.Profile.Corr,
                  Evidence,
                  Spectrum.Similarity,
                  Averagine,
                  Mass.Evidence,
                  CScore,
                  Decoy.Evidence,
                  Decoy.CScore,
                  Fragment.Quant.Raw,
                  Fragment.Quant.Corrected,
                  Fragment.Correlations,
                  MS2.Scan,
                  Fragment.Info,
                  Lib.Index,
                  iIM,
                  Predicted.IM,
                  Predicted.iIM,
                  All.Mapped.Genes
    )
}

#' Join parsed DIA-NN results to the sample annotation table
#'
#' DIA-NN counterpart to [fp_annotate()] — always operates in
#' `"combined_file"`-equivalent mode (DIA-NN's `report.tsv` always carries a
#' `Source_file`/`Run` column), so the merge always matches on `Sample_fp` +
#' `Source_file`. Validates the annotation table, compares matched
#' (`Sample_fp`, `Source_file`) pairs and warns about any that will be
#' dropped, then inner-joins and drops empty factor levels.
#'
#' @param input Output of [diann_parse_pep_all()].
#' @param annotation Annotation data frame; must contain at least `Condition`,
#'   `BioReplicate`, `TechReplicate`, `Sample`, `Sample_fp`, `Source_file`.
#'
#' @return The inner join of `annotation` and `input`, with `Sample_ID`
#'   relocated to the end and empty factor levels dropped.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' diann_annotate(pep_parsed, annotation)
#' }
diann_annotate <- function(input, annotation){
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
  ## check if annotation table contains Source_file
  if(!all(c("Source_file") %in% names(annotation))){
    stop("combined_file mode was activated, but the Source_file column is missing from the annotation table, please add it")
  }
  output <- input %>%
    dplyr::inner_join(annotation, ., by = c("Source_file", "Sample_fp")) %>%
    dplyr::relocate(Sample_ID, .after = "All.Mapped.Genes") %>%
    droplevels() # necessary to avoid dragging empty factors that create errors
  return(output)
}
