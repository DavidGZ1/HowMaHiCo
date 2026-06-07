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
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' read_pep_peaks(getwd(), "JY_PEAKS_01", instrument = "tims_tof")
#' }
read_pep_peaks <- function(filedir, folder_peaks_db, instrument = "tims_tof"){
  pep_renamed <-
    read.csv(file.path(filedir, folder_peaks_db, "peptide.csv")) %>%
    dplyr::rename_with(~ gsub(patt = "[.]", rep = "_", .x), dplyr::everything()) %>%
    dplyr::rename(Score = X_10lgP) %>%
    dplyr::rename_with(~ gsub(patt = "X_", rep = "n_", .x), dplyr::everything()) %>%
    dplyr::mutate(Sequence = gsub("\\s*\\([^\\)]+\\)", "", as.character(Peptide)), # Get striped sequences
                  Charge = as.factor(paste0("+ ", round(Mass / m_z, 0))),
                  Peptide_charge = paste(Peptide, as.numeric(Charge), sep = "_"),
                  Nter = as.factor(stringr::str_sub(Peptide, 1, 1)),
                  Cter = as.factor(stringr::str_sub(Peptide, -1, -1))) %>%
    dplyr::select(-dplyr::starts_with("n_Feature_"))
  pep_long <-
    pep_renamed %>%
    dplyr::rename_with(~ mgsub::mgsub(.x, c("Area_", "ms2r_score_", "ms2r_q_value_pep_"),
                                      c("Area#", "ms2r_score_sample#", "ms2r_q_value_pep_sample#"))) %>%
    tidyr::pivot_longer(cols = tidyr::contains("#"),
                        names_sep = "#",
                        names_to = c(".value", "Sample_peaks"),
                        values_drop_na = TRUE)


  # format IMS
  if(instrument == "tims_tof"){
    output <-
      pep_long %>%
      tidyr::separate(col = X1_k0_Range, into = c("invk0_start", "invk0_end"),
                      sep = "-", convert = TRUE, remove = TRUE) %>%
      dplyr::mutate(invk0 = ((invk0_end + invk0_start) / 2))
  }else{
    if(instrument == "faims_orbi"){
      # quick fix to allow faims_orbi compatibility
      output <-
        pep_long %>%
        dplyr::mutate(X1_k0_Range = paste0(CV, "to", CV)) %>%
        tidyr::separate(col = X1_k0_Range, into = c("invk0_start", "invk0_end"),
                        sep = "to", convert = TRUE, remove = TRUE) %>%
        dplyr::mutate(invk0 = ((invk0_end + invk0_start) / 2))
      # message("faims_orbi is not fully suported yet. For now, the Compensation Voltage (CV) is renamed as invko (1/k0) in the tables and used as mobility dimension in the plots")
    }else{
      if(instrument == "orbi"){
        # quick fix to allow orbi compatibility
        output <-
          pep_long %>%
          dplyr::mutate(CV = NA) %>%
          dplyr::mutate(X1_k0_Range = paste0(CV, "to", CV)) %>%
          tidyr::separate(col = X1_k0_Range, into = c("invk0_start", "invk0_end"),
                          sep = "to", convert = TRUE, remove = TRUE) %>%
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
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' read_qc_peaks("JY_QC_PEAKS_01", sample = "JY_01")
#' }
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
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' read_qc_peaks_single("JY_QC_PEAKS_01", annotation)
#' }
read_qc_peaks_single <- function(folder_peaks_qc, annotation){
  annotation <-
    annotation %>%
    dplyr::select(Condition, BioReplicate, TechReplicate, Sample, Sample_peaks, File_peaks_nb, Fraction_peaks) %>%
    dplyr::mutate(Fraction_peaks = paste0("F", Fraction_peaks))
  output <-
    read.csv(file.path(folder_peaks_qc, "StatisticsTable.csv")) %>%
    dplyr::rename_with(~ sub("Control..", "", .x)) %>%
    dplyr::select(-c(X, Total, Average)) %>%
    dplyr::mutate(dplyr::across(-X.1, ~ as.numeric(sub("%", "", .x)))) %>%
    tibble::column_to_rownames("X.1") %>%
    t %>% as.data.frame() %>%
    janitor::clean_names %>%
    tibble::rownames_to_column("Fraction_peaks") %>%
    dplyr::inner_join(annotation, by = "Fraction_peaks") %>%
    dplyr::relocate(Fraction_peaks, .after = Sample_peaks)


  return(output)
}


#' Batch-read and annotate every PEAKS export folder into `pep_all` format
#'
#' Indexes the PEAKS export subfolders under `folder` (via the vendored
#' [get_dirs_index_peaks()]), filters to those present in `annotation`, reads
#' and joins each one with [read_pep_peaks()], then derives the shared
#' `pep_all` columns (`ProteinFirst`/`GeneFirst`/`OrganismFirst`, `PeptideID`,
#' `Log2Area`, `Length_range`), drops decoys, and warns about any samples that
#' could not be matched to the annotation table.
#'
#' @param folder Top-level directory containing the PEAKS export subfolders.
#' @param annotation Annotation data frame (output of [read_annot()], joined
#'   with [get_dirs_index_peaks()]'s `path_full` column for matching).
#' @param instrument Passed to [read_pep_peaks()]; one of `"tims_tof"`,
#'   `"faims_orbi"`, `"orbi"`.
#' @param shortpep_range Length 2 vector `c(min, max)` defining the
#'   `Length_range` classification window (8-13 AAs for HLA-I).
#'
#' @return The unified `pep_all`-format long data frame for every matched
#'   PEAKS sample.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' peaks_read_batch(file.path("2_data", "peaks_xpro"), annotation,
#'                  instrument = params$Instrument)
#' }
peaks_read_batch <- function(folder, annotation, instrument = "tims_tof", shortpep_range = c(8, 13)){

  # List files
  files_peaks <- get_dirs_index_peaks(folder)
  # filter to only data in the annotation
  files_peaks <- files_peaks[gsub("QC_", "", files_peaks$path_full) %in% unique(annotation$path_full), ]

  output <- lapply(unique(files_peaks[files_peaks$QC == FALSE, "path_full"]),
                   function(x){
                     # x <- unique(files_peaks[files_peaks$QC == FALSE, "path_full"])[4] #for troubleshooting
                     # filter in case there are same sample names across different peaks files
                     annot_x <- annotation %>%
                       dplyr::filter(path_full == files_peaks[files_peaks$path_full == x, "path_full"]) # projectspecific, complete folder was needed here

                     output_raw <- read_pep_peaks(filedir = getwd(),
                                                  folder_peaks_db = x,
                                                  instrument = instrument)
                     output <-
                       output_raw %>%
                       dplyr::rename(Source_File_ID = Source_File) %>%
                       dplyr::inner_join(., annot_x, by = c("Sample_peaks"))

                     if(nrow(output) > nrow(output_raw)) stop("Some samples may be duplicated in the annotation file")
                     message("loaded ", x)
                     return(output)
                   }) %>%
    do.call(args = ., what = dplyr::bind_rows) %>% # clasifier of expected MHC length
    # Get first protein only
    dplyr::mutate(AccessionFirst = sub("\\:.*", "", Accession)) %>%
    dplyr::mutate(AccessionFirst = gsub("|", "_", AccessionFirst, fixed = TRUE)) %>%
    tidyr::separate(AccessionFirst, sep = "_",
                    into = c("ProteinFirst", "GeneFirst", "OrganismFirst"),
                    fill = "right", extra = "drop") %>%
    dplyr::arrange(ProteinFirst, m_z) %>%
    dplyr::mutate(PeptideID = paste0(ProteinFirst, "_", round(m_z, 1), "_", as.numeric(Charge)),
                  Log2Area = ifelse(Area == 0, NA, log(Area, 2)),
                  Length_range = dplyr::case_when(Length >= shortpep_range[1] & Length <= shortpep_range[2] ~
                                                     paste0(shortpep_range[1], " to ", shortpep_range[2], " AAs"),
                                                   Length < shortpep_range[1] | Length > shortpep_range[2] ~ "others"),
                  Length_range = factor(Length_range)) %>%
    dplyr::select(dplyr::any_of( # added any_of and condition names in "" for compatibility with DIA 12/12/2025
      c("Condition", "BioReplicate", "TechReplicate", "Sample",
        "Accession", "Peptide", "Sequence", "Length",
        "Score",
        "Area", "Log2Area",
        "Length_range", "PTM", "AScore", "Charge", "Nter", "Cter",
        "RT", "invk0_start", "invk0", "invk0_end", "Mass", "ppm", "m_z",
        "Sample_ID", "Sample_peaks", "Source_File", "File_peaks_nb",
        "Source_File_ID", "Precursor_Id", "n_Feature", "Found_By", "PeptideID", "ProteinFirst", "GeneFirst", "OrganismFirst")
    )) # removed: Fraction, Peptide_charge, path_full, Fraction_peaks

  if(any(grepl("#DECOY#", output$Accession))){
    output <- output %>% dplyr::filter(!grepl("#DECOY#", Accession))
    message("Decoys were included in the raw results. They have been filtered out")
  }

  # Check if any non-matched sample
  if(any(is.na(output$Condition))){
    warning("The following samples were not matched with the annotation file and thus will be droped")
    output %>%
      dplyr::filter(is.na(Condition)) %>%
      dplyr::select(Condition, Sample, Source_File, Sample_peaks, File_peaks_nb) %>% unique %>%
      kableExtra::kable %>%
      kableExtra::kable_paper("hover", full_width = F) %>%
      print()
  }
  return(output)

}
