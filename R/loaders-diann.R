#' Read one DIA-NN `report.tsv` file
#'
#' Thin wrapper around [read_fragpipe()] for API symmetry — DIA-NN report files
#' use the same generic TSV format as FragPipe PSM files; the two loaders only
#' diverge during the parse step ([parse_diann()] vs [parse_fragpipe()]).
#'
#' @param folder Path to the `report.tsv` file to read.
#' @param samplename Sample identifier to record in the new `Sample_fp` column.
#' @param testmode Logical; if `TRUE`, reads only the first ~100 rows.
#'
#' @return The tsv contents as a data frame, with `Sample_fp` added and
#'   relocated to the first column.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_diann("2_data/diann/JY/report.tsv", "JY", testmode = FALSE)
#' }
read_diann <- function(folder, samplename, testmode = FALSE) {
  read_fragpipe(folder, samplename, testmode = testmode)
}

#' Batch-read DIA-NN `report.tsv` files and merge them
#'
#' Reads all DIA-NN `report.tsv` files and row-binds the result. Three input
#' modes are supported (checked in priority order):
#'
#' 1. **`files`** — character vector of `report.tsv` file paths or their parent
#'    folder paths; sample names are taken from the immediate parent folder.
#' 2. **`annotation`** — only the `Sample_fp` entries listed in the annotation
#'    table are read from `folder`; warns about any annotated samples not found
#'    on disk.
#' 3. **neither** — `folder` is scanned recursively for every `report.tsv`
#'    (original default behaviour).
#'
#' @param folder Top-level directory. Required when using the `annotation` or
#'   scan-all modes; unused when `files` is supplied.
#' @param annotation Optional annotation data frame (output of [read_annot()]).
#'   When provided without `files`, only `Sample_fp` entries present in
#'   `annotation` are read.
#' @param files Optional character vector of `report.tsv` file paths or parent
#'   folder paths to read directly.
#' @param testmode Logical; passed through to [read_diann()] (loads only the
#'   first ~100 rows per file when `TRUE`, for fast iteration).
#'
#' @return The merged raw DIA-NN report data frame across every file found,
#'   with `Sample_fp` identifying the source subfolder of each row.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # scan entire folder
#' read_diann_batch(file.path("2_data", "diann"), testmode = FALSE)
#'
#' # restrict to annotated samples only
#' read_diann_batch(folder = "2_data", annotation = annot)
#'
#' # provide paths explicitly
#' read_diann_batch(files = c("2_data/diann/JY_1/report.tsv", "2_data/diann/JY_2"))
#' }
read_diann_batch <- function(folder = NULL, annotation = NULL, files = NULL,
                              testmode = FALSE){
  if (!is.null(files)) {
    file_paths <- ifelse(
      endsWith(files, "report.tsv"), files,
      file.path(files, "report.tsv")
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
    file_paths  <- file.path(folder, sample_fps, "report.tsv")
    missing     <- !file.exists(file_paths)
    if (any(missing))
      warning("The following annotated samples were not found on disk and will be skipped:\n",
              paste(sample_fps[missing], collapse = ", "))
    file_paths   <- file_paths[!missing]
    sample_names <- sample_fps[!missing]
  } else {
    if (is.null(folder)) stop("'folder' must be provided when 'annotation' and 'files' are both NULL")
    files_data_all <- list.files(folder, recursive = TRUE)
    file_paths   <- file.path(folder, files_data_all[grepl("report.tsv", files_data_all, fixed = TRUE)])
    sample_names <- stringr::str_match(file_paths, "[/]\\s*(.*?)\\s*[/]report.tsv")[, 2]
  }

  psm_raw_list <- lapply(seq_along(file_paths), function(x){
    read_diann(file_paths[x], sample_names[x], testmode = testmode)
  })
  do.call(args = psm_raw_list, what = dplyr::bind_rows)
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
#' @param input Output of [read_diann_batch()].
#' @param shortpep_range Length 2 vector `c(min, max)` defining the
#'   `Length_range` classification window (8-13 AAs for HLA-I).
#'
#' @return The input reshaped into `pep_all` long format.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' parse_diann(read_diann_batch(folder), shortpep_range = c(8, 13))
#' }
parse_diann <- function(input, shortpep_range = c(8, 13)){
  # mass and ppm not calculated
  input |>
    dplyr::rename_with(~ gsub(patt = " ", rep = ".", .x), dplyr::everything()) |>
    dplyr::mutate(
      PeptideID = paste0(All.Mapped.Proteins, "_", round(Precursor.Mz, 1), "_", as.numeric(Precursor.Charge)),
      OrganismFirst = gsub(".*_(.+).*", "\\1", All.Mapped.Proteins),
      Log2Area = compute_log2area(Ms1.Area),
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
      Source_file = extract_run_name(File.Name),
      Found_By = "DIA-NN"
    ) |>
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
    ) |>
    validate_pep_all("DIA-NN")
}

#' Join parsed DIA-NN results to the sample annotation table
#'
#' DIA-NN counterpart to [annotate_fragpipe()] — always operates in
#' `"combined_file"`-equivalent mode (DIA-NN's `report.tsv` always carries a
#' `Source_file`/`Run` column), so the merge always matches on `Sample_fp` +
#' `Source_file`. Validates the annotation table, compares matched
#' (`Sample_fp`, `Source_file`) pairs and warns about any that will be
#' dropped, then inner-joins and drops empty factor levels.
#'
#' @param input Output of [parse_diann()].
#' @param annotation Annotation data frame; must contain at least `Condition`,
#'   `BioReplicate`, `TechReplicate`, `Sample`, `Sample_fp`, `Source_file`.
#'
#' @return The inner join of `annotation` and `input`, with `Sample_ID`
#'   relocated to the end and empty factor levels dropped.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' annotate_diann(pep_parsed, annotation)
#' }
annotate_diann <- function(input, annotation){
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
  ## check if annotation table contains Source_file
  if(!all(c("Source_file") %in% names(annotation))){
    stop("combined_file mode was activated, but the Source_file column is missing from the annotation table, please add it")
  }
  output <- input |>
    (\(x) dplyr::inner_join(annotation, x, by = c("Source_file", "Sample_fp")))() |>
    dplyr::relocate(Sample_ID, .after = "All.Mapped.Genes") |>
    droplevels() # necessary to avoid dragging empty factors that create errors
  return(output)
}
