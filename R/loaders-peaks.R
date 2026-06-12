#' Read one PEAKS `peptide.csv` export into long format
#'
#' Reads `peptide.csv` from a PEAKS export subfolder, renames/derives the
#' core columns (`Sequence`, `Charge`, `Nter`/`Cter`, ...), pivots the
#' per-sample `Area#<sample>`/`ms2r_score_#<sample>`/... columns into long
#' format, and parses the ion-mobility column according to `instrument`.
#'
#' @param filedir Top-level directory containing `folder_peaks_db`.
#' @param folder_peaks_db PEAKS export subfolder name (relative to `filedir`)
#'   containing `peptide.csv`.
#' @param instrument One of `"tims_tof"` (parses the `X1_k0_Range` column
#'   directly into `invk0`), `"faims_orbi"`, or `"orbi"` (both repurpose
#'   Compensation Voltage `CV` as a stand-in for `invk0` — "not fully
#'   supported yet").
#'
#' @return A long-format data frame with one row per peptide-sample
#'   observation, including the parsed `invk0`/`invk0_start`/`invk0_end`
#'   columns.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_peaks(getwd(), "JY_PEAKS_01", instrument = "tims_tof")
#' }
read_peaks <- function(filedir, folder_peaks_db, instrument = "tims_tof"){
  pep_renamed <-
    read.csv(file.path(filedir, folder_peaks_db, "peptide.csv")) |>
    dplyr::rename_with(~ gsub(patt = "[.]", rep = "_", .x), dplyr::everything()) |>
    dplyr::rename(Score = X_10lgP) |>
    dplyr::rename_with(~ gsub(patt = "X_", rep = "n_", .x), dplyr::everything()) |>
    dplyr::mutate(Sequence = gsub("\\s*\\([^\\)]+\\)", "", as.character(Peptide)), # Get striped sequences
                  Charge = as.factor(paste0("+ ", round(Mass / m_z, 0))),
                  Peptide_charge = paste(Peptide, as.numeric(Charge), sep = "_"),
                  Nter = as.factor(stringr::str_sub(Peptide, 1, 1)),
                  Cter = as.factor(stringr::str_sub(Peptide, -1, -1))) |>
    dplyr::select(-dplyr::starts_with("n_Feature_"))
  pep_long <-
    pep_renamed |>
    dplyr::rename_with(~ mgsub::mgsub(.x, c("Area_", "ms2r_score_", "ms2r_q_value_pep_"),
                                      c("Area#", "ms2r_score_sample#", "ms2r_q_value_pep_sample#"))) |>
    tidyr::pivot_longer(cols = tidyr::contains("#"),
                        names_sep = "#",
                        names_to = c(".value", "Sample_peaks"),
                        values_drop_na = TRUE)


  # format IMS
  if(instrument == "tims_tof"){
    output <-
      pep_long |>
      tidyr::separate(col = X1_k0_Range, into = c("invk0_start", "invk0_end"),
                      sep = "-", convert = TRUE, remove = TRUE) |>
      dplyr::mutate(invk0 = ((invk0_end + invk0_start) / 2))
  }else{
    if(instrument == "faims_orbi"){
      # quick fix to allow faims_orbi compatibility
      output <-
        pep_long |>
        dplyr::mutate(X1_k0_Range = paste0(CV, "to", CV)) |>
        tidyr::separate(col = X1_k0_Range, into = c("invk0_start", "invk0_end"),
                        sep = "to", convert = TRUE, remove = TRUE) |>
        dplyr::mutate(invk0 = ((invk0_end + invk0_start) / 2))
      # message("faims_orbi is not fully suported yet. For now, the Compensation Voltage (CV) is renamed as invko (1/k0) in the tables and used as mobility dimension in the plots")
    }else{
      if(instrument == "orbi"){
        # quick fix to allow orbi compatibility
        output <-
          pep_long |>
          dplyr::mutate(CV = NA) |>
          dplyr::mutate(X1_k0_Range = paste0(CV, "to", CV)) |>
          tidyr::separate(col = X1_k0_Range, into = c("invk0_start", "invk0_end"),
                          sep = "to", convert = TRUE, remove = TRUE) |>
          dplyr::mutate(invk0 = ((invk0_end + invk0_start) / 2))
        # message("orbi is not fully suported yet. For now, the Compensation Voltage (CV) is renamed as invko (1/k0) in the tables and used as mobility dimension in the plots")
      }
    }
    return(output)
  }
}

#' Read one PEAKS QC `StatisticsTable.csv` into a one-row summary
#'
#' @param folder_peaks_qc PEAKS QC export subfolder containing
#'   `StatisticsTable.csv`.
#' @param sample Sample name to record in the output's `Sample` column.
#'
#' @return A one-row data frame of QC statistics, with `Sample` prepended.
#'
#'
#' @examples
#' \dontrun{
#' read_qc_peaks("JY_QC_PEAKS_01", sample = "JY_01")
#' }
#' @keywords internal
read_qc_peaks <- function(folder_peaks_qc, sample){
  output <- read.csv(file.path(folder_peaks_qc, "StatisticsTable.csv"))
  output[, 3] <- as.numeric(sub("%", "", output[, 3]))
  output <- as.data.frame(t(tibble::column_to_rownames(output[, c(2, 3)], "X.1")))
  output <- janitor::clean_names(output)
  row.names(output) <- NULL
  output <- cbind(Sample = sample, output)
  return(output)
}

#' Read a PEAKS QC `StatisticsTable.csv` covering several fractions
#'
#' Variant of [read_qc_peaks()] for a single PEAKS QC export that reports
#' several fractions side by side — pivots the per-fraction columns into long
#' format and joins them onto the corresponding annotation rows by
#' `Fraction_peaks`.
#'
#' @param folder_peaks_qc PEAKS QC export folder containing
#'   `StatisticsTable.csv`.
#' @param annotation Annotation data frame; must contain `Condition`,
#'   `BioReplicate`, `TechReplicate`, `Sample`, `Sample_peaks`,
#'   `File_peaks_nb`, `Fraction_peaks`.
#'
#' @return A data frame of per-fraction QC statistics joined to the matching
#'   annotation rows.
#'
#'
#' @examples
#' \dontrun{
#' read_qc_peaks_single("JY_QC_PEAKS_01", annotation)
#' }
#' @keywords internal
read_qc_peaks_single <- function(folder_peaks_qc, annotation){
  annotation <-
    annotation |>
    dplyr::select(Condition, BioReplicate, TechReplicate, Sample, Sample_peaks, File_peaks_nb, Fraction_peaks) |>
    dplyr::mutate(Fraction_peaks = paste0("F", Fraction_peaks))
  output <-
    read.csv(file.path(folder_peaks_qc, "StatisticsTable.csv")) |>
    dplyr::rename_with(~ sub("Control..", "", .x)) |>
    dplyr::select(-c(X, Total, Average)) |>
    dplyr::mutate(dplyr::across(-X.1, ~ as.numeric(sub("%", "", .x)))) |>
    tibble::column_to_rownames("X.1") |>
    t() |> as.data.frame() |>
    janitor::clean_names() |>
    tibble::rownames_to_column("Fraction_peaks") |>
    dplyr::inner_join(annotation, by = "Fraction_peaks") |>
    dplyr::relocate(Fraction_peaks, .after = Sample_peaks)


  return(output)
}


#' Batch-read PEAKS export folders and merge them into raw long format
#'
#' Indexes the PEAKS export subfolders (via
#' [get_dirs_index_peaks()]), selects which to read, then reads and row-binds
#' each one with [read_peaks()]. Three input modes are supported (checked in
#' priority order):
#'
#' 1. **`files`** — character vector of PEAKS export folder paths; uses those
#'    directly, bypassing the directory index.
#' 2. **`annotation`** — filters the directory index to subfolders whose
#'    `basename` is listed in `annotation$Sample_peaks`.
#' 3. **neither** — all non-QC PEAKS subfolders under `folder` are read.
#'
#' The metadata join (adding `Condition`, `BioReplicate`, `Sample`, etc.)
#' happens in [annotate_peaks()], not here. This function returns the raw
#' long-format PEAKS data only.
#'
#' @param folder Top-level directory containing the PEAKS export subfolders.
#'   Required when using `annotation` or scan-all modes; may be `NULL` when
#'   `files` is supplied.
#' @param annotation Optional annotation data frame (output of [read_annot()]).
#'   When provided without `files`, only subfolders whose `basename` is in
#'   `annotation$Sample_peaks` are read.
#' @param files Optional character vector of PEAKS export folder paths to read
#'   directly, bypassing the directory index.
#' @param instrument Passed to [read_peaks()]; one of `"tims_tof"`,
#'   `"faims_orbi"`, `"orbi"`.
#'
#' @return The raw long-format PEAKS data frame across every matched subfolder,
#'   with `Sample_peaks` identifying the source subfolder of each row.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_peaks_batch(file.path("2_data", "peaks_xpro"), annotation,
#'                  instrument = "tims_tof")
#'
#' # explicit folder paths
#' read_peaks_batch(files = c("peaks_xpro/JY_01", "peaks_xpro/JY_02"))
#' }
read_peaks_batch <- function(folder = NULL, annotation = NULL, files = NULL,
                              instrument = "tims_tof"){

  if (!is.null(files)) {
    paths_to_read <- files
  } else {
    if (is.null(folder)) stop("'folder' must be provided when 'files' is NULL")
    files_peaks <- get_dirs_index_peaks(folder)
    files_peaks_data <- files_peaks[files_peaks$QC == FALSE, ]
    if (!is.null(annotation)) {
      annotated <- unique(as.character(annotation$Sample_peaks))
      files_peaks_data <- files_peaks_data[basename(files_peaks_data$path_full) %in% annotated, ]
    }
    paths_to_read <- unique(files_peaks_data$path_full)
  }

  lapply(paths_to_read, function(x) {
    out <- read_peaks(filedir = getwd(), folder_peaks_db = x, instrument = instrument)
    message("loaded ", x)
    out
  }) |>
    (\(x) do.call(dplyr::bind_rows, x))()
}


#' Parse raw PEAKS results into `pep_all` format
#'
#' Derives the shared `pep_all` columns (`ProteinFirst`/`GeneFirst`/
#' `OrganismFirst`, `PeptideID`, `Log2Area`, `Length_range`, `Found_By`) from
#' the output of [read_peaks_batch()] and selects/reorders columns to converge
#' on the unified schema shared with the FragPipe and DIA-NN loaders.
#'
#' @param input Output of [read_peaks_batch()].
#' @param shortpep_range Length 2 vector `c(min, max)` defining the
#'   `Length_range` classification window (8-13 AAs for HLA-I).
#'
#' @return The input reshaped into `pep_all` long format (without annotation
#'   columns — call [annotate_peaks()] next).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' parse_peaks(read_peaks_batch(folder, annotation), shortpep_range = c(8, 13))
#' }
parse_peaks <- function(input, shortpep_range = c(8, 13)){
  input |>
    dplyr::rename(dplyr::any_of(c(Source_File_ID = "Source_File"))) |>
    dplyr::mutate(
      AccessionFirst = gsub("|", "_", sub("\\:.*", "", Accession), fixed = TRUE)
    ) |>
    tidyr::separate(AccessionFirst, sep = "_",
                    into = c("ProteinFirst", "GeneFirst", "OrganismFirst"),
                    fill = "right", extra = "drop") |>
    dplyr::arrange(ProteinFirst, m_z) |>
    dplyr::mutate(
      PeptideID = paste0(ProteinFirst, "_", round(m_z, 1), "_", as.numeric(Charge)),
      Log2Area = ifelse(Area == 0, NA, log(Area, 2)),
      Length_range = dplyr::case_when(
        Length >= shortpep_range[1] & Length <= shortpep_range[2] ~
          paste0(shortpep_range[1], " to ", shortpep_range[2], " AAs"),
        Length < shortpep_range[1] | Length > shortpep_range[2] ~ "others"),
      Length_range = factor(Length_range),
      Found_By = "PEAKS"
    ) |>
    dplyr::select(dplyr::any_of(
      c("Accession", "Peptide", "Sequence", "Length",
        "Score",
        "Area", "Log2Area",
        "Length_range", "PTM", "AScore", "Charge", "Nter", "Cter",
        "RT", "invk0_start", "invk0", "invk0_end", "Mass", "ppm", "m_z",
        "Sample_peaks", "File_peaks_nb",
        "Source_File_ID", "Precursor_Id", "n_Feature", "Found_By",
        "PeptideID", "ProteinFirst", "GeneFirst", "OrganismFirst")
    ))
}


#' Join parsed PEAKS results to the sample annotation table
#'
#' Validates that the annotation table has the minimal required columns,
#' inner-joins `input` with `annotation` on `Sample_peaks`, warns about any
#' unmatched samples, and filters out decoy identifications.
#'
#' @param input Output of [parse_peaks()].
#' @param annotation Annotation data frame; must contain at least `Condition`,
#'   `BioReplicate`, `TechReplicate`, `Sample`, `Sample_peaks`.
#'
#' @return The inner join of `annotation` and `input`, with decoys removed.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' annotate_peaks(parse_peaks(read_peaks_batch(folder, annotation)), annotation)
#' }
annotate_peaks <- function(input, annotation){
  minimal_columns <- c("Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_peaks")
  if (!all(minimal_columns %in% names(annotation))) {
    stop(paste0("The following columns are missing from the annotation table, please add them:\n",
                paste0(minimal_columns[!minimal_columns %in% names(annotation)], collapse = ", ")))
  }

  output <- dplyr::inner_join(annotation, input, by = "Sample_peaks")

  if (nrow(output) > nrow(input)) {
    stop("Some samples may be duplicated in the annotation file")
  }

  if (any(grepl("#DECOY#", output$Accession))) {
    output <- output |> dplyr::filter(!grepl("#DECOY#", Accession))
    message("Decoys were included in the raw results. They have been filtered out")
  }

  if (any(is.na(output$Condition))) {
    warning("The following samples were not matched with the annotation file and thus will be dropped")
    output |>
      dplyr::filter(is.na(Condition)) |>
      dplyr::select(dplyr::any_of(c("Condition", "Sample", "Source_File_ID", "Sample_peaks", "File_peaks_nb"))) |>
      unique() |>
      kableExtra::kable() |>
      kableExtra::kable_paper("hover", full_width = FALSE) |>
      print()
    output <- output |> dplyr::filter(!is.na(Condition))
  }

  return(output)
}
