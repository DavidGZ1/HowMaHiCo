# Synthetic-data builders shared across test files. Kept tiny and
# hand-constructed (not trimmed real search-engine output) so the schema each
# function expects is documented in code, the suite stays fast/deterministic,
# and no real/unpublished instrument data ever needs to ship with the package.

#' A small synthetic `pep_all`-shaped data frame
#'
#' 2 conditions x 2 biological replicates x 2 technical replicates, a handful
#' of peptides (some shared across conditions, one decoy, one contaminant, one
#' "short"/HLA-I-length peptide and one "other"-length one), 2 charge states.
#' Covers every column the counting/overlap/select-filter helpers group or
#' summarise on, including the upsets-report-specific `Patient`/`Sample_type`
#' columns (derived there from `Condition` via `separate_wider_delim`).
make_pep_all <- function(){
  base <- tibble::tribble(
    ~Condition, ~Sample,   ~Peptide,        ~Sequence,    ~Length, ~Accession,                ~ProteinFirst, ~GeneFirst, ~OrganismFirst, ~Charge, ~Area,
    "JY_tissue",  "JY_1",  "AAAVAAAAL",     "AAAVAAAAL",  9L,      "sp|P11111|AAA1_HUMAN",    "P11111",      "AAA1",     "HUMAN",        2,       12000,
    "JY_tissue",  "JY_1",  "GILGFVFTL",     "GILGFVFTL",  9L,      "sp|P22222|BBB1_HUMAN",    "P22222",      "BBB1",     "HUMAN",        2,       20000,
    "JY_tissue",  "JY_2",  "AAAVAAAAL",     "AAAVAAAAL",  9L,      "sp|P11111|AAA1_HUMAN",    "P11111",      "AAA1",     "HUMAN",        2,       11000,
    "JY_tissue",  "JY_2",  "NLVPMVATVQGQNLK", "NLVPMVATVQGQNLK", 15L, "sp|P33333|CCC1_HUMAN", "P33333",      "CCC1",     "HUMAN",        2,       9000,
    "JY_plasma",  "JY_3",  "AAAVAAAAL",     "AAAVAAAAL",  9L,      "sp|P11111|AAA1_HUMAN",    "P11111",      "AAA1",     "HUMAN",        2,       8000,
    "JY_plasma",  "JY_3",  "SIINFEKL",      "SIINFEKL",   8L,      "sp|P44444|DDD1_HUMAN",    "P44444",      "DDD1",     "HUMAN",        1,       15000,
    "JY_plasma",  "JY_4",  "SIINFEKL",      "SIINFEKL",   8L,      "sp|P44444|DDD1_HUMAN",    "P44444",      "DDD1",     "HUMAN",        1,       14000,
    "JY_plasma",  "JY_4",  "DECOYPEPTIDE",  "DECOYPEPTIDE", 12L,   "#DECOY#sp|P00000|XXX_HUMAN", "#DECOY#P00000", "XXX1", "HUMAN",  3,       1000,
    "MM_plasma",  "MM_1",  "GILGFVFTL",     "GILGFVFTL",  9L,      "sp|P22222|BBB1_HUMAN",    "P22222",      "BBB1",     "HUMAN",        2,       18000,
    "MM_plasma",  "MM_1",  "CONTAMINANTPEP", "CONTAMINANTPEP", 14L, "Cont_sp|P99999|CON_HUMAN", "P99999",   "CON",      "HUMAN",        2,       2000
  )

  base %>%
    dplyr::mutate(
      BioReplicate = sub("_[0-9]+$", "", Sample),
      TechReplicate = sub(".*_", "", Sample),
      Sample_ID = paste0(Sample, "_ID"),
      Patient = sub("_.*", "", Condition),
      Sample_type = sub(".*_", "", Condition),
      PTM = "",
      Score = 40,
      Log2Area = log2(Area),
      Charge = factor(paste0("+ ", Charge), levels = c("+ 1", "+ 2", "+ 3")),
      Nter = factor(substr(Sequence, 1, 1)),
      Cter = factor(substr(Sequence, nchar(Sequence), nchar(Sequence))),
      Length_range = factor(dplyr::if_else(Length >= 8 & Length <= 13, "8 to 13 AAs", "others"),
                            levels = c("8 to 13 AAs", "others")),
      RT = 10 + Length,
      invk0 = 0.7 + Length / 100,
      Mass = Length * 110,
      ppm = 0,
      m_z = Mass / 2,
      Source_file = paste0(Sample, "_run"),
      Source_File_ID = paste0(Sample, "_run.d"),
      Precursor_Id = paste0(Sequence, ".", Charge),
      Found_By = "Test",
      PeptideID = paste0(ProteinFirst, "_", round(m_z, 1), "_", as.numeric(Charge))
    ) %>%
    dplyr::mutate(dplyr::across(c(Condition, Sample, BioReplicate, TechReplicate, Sample_ID,
                                  Patient, Sample_type, Source_file, Source_File_ID),
                                ~ factor(.x, levels = unique(.x)))) %>%
    dplyr::relocate(Sample_ID, .after = Sample)
}

#' A minimal synthetic sample-annotation data frame
#'
#' Matches `make_pep_all()`'s `Sample`/`Condition`/`BioReplicate`/
#' `TechReplicate` columns one-to-one, with the loader-specific `Sample_fp`/
#' `Source_file`/`Sample_peaks` join keys included so it can stand in for
#' `read_annot()`'s output across all three loader families.
make_annot <- function(){
  tibble::tribble(
    ~Condition,  ~BioReplicate, ~TechReplicate, ~Sample, ~Sample_ID, ~Sample_fp, ~Source_file, ~Sample_peaks,
    "JY_tissue", "JY_1",        "1",            "JY_1",  "JY_1_ID",  "JY_1",     "JY_1_run",   "JY_1",
    "JY_tissue", "JY_2",        "1",            "JY_2",  "JY_2_ID",  "JY_2",     "JY_2_run",   "JY_2",
    "JY_plasma", "JY_3",        "1",            "JY_3",  "JY_3_ID",  "JY_3",     "JY_3_run",   "JY_3",
    "JY_plasma", "JY_4",        "1",            "JY_4",  "JY_4_ID",  "JY_4",     "JY_4_run",   "JY_4",
    "MM_plasma", "MM_1",        "1",            "MM_1",  "MM_1_ID",  "MM_1",     "MM_1_run",   "MM_1"
  ) %>%
    dplyr::mutate(dplyr::across(dplyr::where(is.character), ~ factor(.x, levels = unique(.x))))
}

#' A synthetic raw-FragPipe-PSM-shaped data frame (post `fp_read_psm`)
#'
#' One `Sample_fp` value, 4 PSM rows (one modified, one with a zero
#' intensity) — covers every column [fp_parse_pep_all()] reads/renames.
make_fp_psm_raw <- function(samplename = "JY_1"){
  tibble::tribble(
    ~Sample_fp, ~`Modified Peptide`, ~Peptide,    ~Protein,                  ~`Calibrated Observed M/Z`, ~Charge, ~`Entry Name`,    ~Intensity, ~Retention, ~`Peptide Length`, ~`Calculated M/Z`, ~Spectrum,             ~Hyperscore, ~`Assigned Modifications`, ~`Ion Mobility`, ~`Calibrated Observed Mass`, ~`Spectrum File`, ~`Protein ID`, ~Gene,   ~Nextscore, ~Probability, ~Qvalue, ~`Protein Description`, ~`Mapped Genes`, ~`Mapped Proteins`, ~`Is Decoy`, ~`Is Contaminant`, ~`Is Unique`,
    samplename, NA_character_,        "AAAVAAAAL", "sp|P11111|AAA1_HUMAN",    527.3,                      2,       "AAA1_HUMAN",     12000,      750,        9L,                526.8,             "run1.123.123.2",      35.1,        "",                        0.78,            1052.6,                       "run1.d",         "P11111",      "AAA1",  30.2,       0.99,         0.01,    "Test protein 1",       "AAA1",          "P11111",           "N",         "N",               "Y",
    samplename, "AAAVAAAAL(15.9949)", "AAAVAAAAL", "sp|P11111|AAA1_HUMAN",    533.3,                      2,       "AAA1_HUMAN",     5000,       760,        9L,                532.8,             "run1.124.124.2",      33.0,        "M5(15.9949)",             0.79,            1064.6,                       "run1.d",         "P11111",      "AAA1",  28.0,       0.97,         0.02,    "Test protein 1",       "AAA1",          "P11111",           "N",         "N",               "Y",
    samplename, NA_character_,        "GILGFVFTL", "sp|P22222|BBB1_HUMAN",    509.3,                      2,       "BBB1_HUMAN",     20000,      900,        9L,                508.8,             "run1.200.200.2",      40.5,        "",                        0.81,            1016.6,                       "run1.d",         "P22222",      "BBB1",  35.0,       0.99,         0.01,    "Test protein 2",       "BBB1",          "P22222",           "N",         "N",               "Y",
    samplename, NA_character_,        "ZEROAREAPEP", "sp|P33333|CCC1_HUMAN",  600.0,                      2,       "CCC1_HUMAN",     0,          1000,       15L,               599.5,             "run1.300.300.2",      20.0,        "",                        0.85,            1198.0,                       "run1.d",         "P33333",      "CCC1",  18.0,       0.80,         0.05,    "Test protein 3",       "CCC1",          "P33333",           "N",         "N",               "Y"
  ) %>%
    dplyr::mutate(Spectrum = as.character(Spectrum))
}

#' A `Condition` x `Charge_group` (incl. `"Total"`) count table
#'
#' Mirrors the `count_all_condition_charge` table the main report builds just
#' before calling [get_proportion_charge()] (`bind_rows()` of a per-group
#' [count_ids()] and a `Charge_group = "Total"` summary) — the function
#' requires a `"Total"` row per `Condition` to compute proportions against.
make_count_charge_table <- function(){
  pep_all <- make_pep_all() %>% get_charge_group()
  dplyr::bind_rows(
    pep_all %>% dplyr::group_by(Condition, Charge_group) %>% count_ids() %>%
      dplyr::arrange(Condition, Charge_group),
    pep_all %>% dplyr::group_by(Condition) %>% count_ids() %>%
      dplyr::mutate(Charge_group = "Total")
  ) %>%
    dplyr::mutate(Charge_group = factor(Charge_group, rev(unique(Charge_group))))
}

#' A synthetic raw-DIA-NN-report-shaped data frame (post `fp_read_psm`)
#'
#' One `Sample_fp` value, 3 precursor rows — covers every column
#' [diann_parse_pep_all()] reads/renames/selects (the long tail of
#' `Suggests`-only DIA-NN-report passthrough columns are filled with `NA`).
make_diann_report_raw <- function(samplename = "JY_1"){
  core <- tibble::tribble(
    ~Sample_fp, ~`File.Name`,                ~`Run`,  ~`Protein.Group`, ~`Protein.Ids`, ~`Protein.Names`, ~`All.Mapped.Proteins`,    ~`Genes`, ~`All.Mapped.Genes`, ~`Modified.Sequence`,   ~`Stripped.Sequence`, ~`Precursor.Id`,        ~`Precursor.Charge`, ~`Q.Value`, ~`Ms1.Area`, ~`Precursor.Mz`, ~RT,  ~IM,   ~`Precursor.Normalised`,
    samplename, "D:\\data\\run1.d",          "run1",  "P11111",         "P11111",       "AAA1_HUMAN",     "sp|P11111|AAA1_HUMAN",    "AAA1",   "AAA1",              "AAAVAAAAL",            "AAAVAAAAL",          "AAAVAAAAL2",           2,                   0.001,      12000,       527.3,           7.5,  0.78,  11000,
    samplename, "D:\\data\\run1.d",          "run1",  "P22222",         "P22222",       "BBB1_HUMAN",     "sp|P22222|BBB1_HUMAN",    "BBB1",   "BBB1",              "GILGFVFTL",            "GILGFVFTL",          "GILGFVFTL2",           2,                   0.002,      20000,       509.3,           9.0,  0.81,  19000,
    samplename, "D:\\data\\run1.d",          "run1",  "P33333",         "P33333",       "CCC1_HUMAN",     "sp|P33333|CCC1_HUMAN",    "CCC1",   "CCC1",              "ZEROAREA(UniMod:35)PEP", "ZEROAREAPEP",      "ZEROAREAPEP2",         2,                   0.05,       0,           600.0,           10.0, 0.85,  0
  )

  passthrough_cols <- c("PG.Quantity", "PG.Normalised", "PG.MaxLFQ", "Genes.Quantity",
                        "Genes.Normalised", "Genes.MaxLFQ", "Genes.MaxLFQ.Unique", "PEP",
                        "Global.Q.Value", "Protein.Q.Value", "PG.Q.Value", "Global.PG.Q.Value",
                        "GG.Q.Value", "Translated.Q.Value", "Proteotypic", "Precursor.Quantity",
                        "Precursor.Translated", "Translated.Quality", "Ms1.Translated",
                        "Quantity.Quality", "iRT", "RT.Start", "RT.Stop", "Predicted.RT",
                        "Predicted.iRT", "Lib.Q.Value", "Lib.PG.Q.Value", "Ms1.Profile.Corr",
                        "Evidence", "Spectrum.Similarity", "Averagine", "Mass.Evidence",
                        "CScore", "Decoy.Evidence", "Decoy.CScore", "Fragment.Quant.Raw",
                        "Fragment.Quant.Corrected", "Fragment.Correlations", "MS2.Scan",
                        "Fragment.Info", "Lib.Index", "iIM", "Predicted.IM", "Predicted.iIM")
  for(col in passthrough_cols) core[[col]] <- NA_real_

  core
}
