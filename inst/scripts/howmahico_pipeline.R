# ==============================================================================
# HowMaHiCo — guided analysis pipeline
# ==============================================================================
#
# A runnable walkthrough of a complete LC-immunopeptidomics analysis: from raw
# search-engine output to rendered HTML QC reports and csv/xlsx result tables.
#
# Get your own copy of this file with:
#     HowMaHiCo::get_pipeline_script("howmahico_pipeline.R")
#
# The narrated version of the same walkthrough is `vignette("howmahico")`.
#
# HOW TO USE IT
#   * Leave RUN_DEMO = TRUE and source the whole file. It runs end to end on a
#     small simulated dataset that ships with the package, so you can see the
#     outputs before pointing it at your own data.
#   * Then set RUN_DEMO = FALSE, edit the CONFIG block, and work through the
#     steps in order.
#
# Reports are produced with run_howmahico_report(), which calls
# rmarkdown::render() for you — you never need to open a template and knit it
# by hand.
# ==============================================================================

library(HowMaHiCo)

# If the package is not installed yet, use one of:
#   install.packages("remotes"); remotes::install_github("DavidGZ1/HowMaHiCo")
#   devtools::load_all()            # from a clone of the repository
# The advanced-quantification report (06) additionally wants limma:
#   install.packages("BiocManager"); BiocManager::install("limma")
# Without limma that report still runs — it falls back to a Welch t-test.


# ==============================================================================
# 0. Demo mode
# ==============================================================================
# TRUE  = run against the simulated FragPipe dataset shipped in the package
#         (2 Conditions x 3 BioReplicates), in a temporary folder.
# FALSE = run against your own data, using the CONFIG block below.

RUN_DEMO <- TRUE


# ==============================================================================
# 1. CONFIG — the only block you normally edit
# ==============================================================================
# Folder paths are absolute, or relative to the working directory you render
# from. The report templates live inside the installed package, so they can be
# rendered from anywhere; nothing is assumed about the project layout.

CONFIG <- list(
  SampleSet   = "my_experiment",       # human-readable experiment name, used in report titles
  Subset      = "dda_all",             # subset label: filename prefix + results/figures subfolder
  Provider    = "",                    # your lab/platform; "" prints a generic attribution
  Software    = "fragpipe_dda_combined", # fragpipe_dda_combined | fragpipe_dda_individual | diann | peaks_xpro | custom
  Instrument  = "tims_tof",            # tims_tof | faims_orbi | orbi  (affects PEAKS ion-mobility parsing)
  MHCclass    = "MHC1",                # MHC1 (human, 8-13 AA) | MHC1_mouse (7-11 AA) | MHC2 (12-25 AA)

  FolderDocumentation = "1_documentation", # holds the annotation csv
  AnnotationFile      = "sample_annotation.csv",
  FolderData          = "2_data",          # raw search output + the pep_all cache
  FolderResults       = "3_results",       # csv / xlsx output
  FolderFigures       = "4_figures",       # png output (only when PlotsSave = TRUE)
  ProjectDir          = getwd()            # project root; relative paths above resolve from here
)

if (RUN_DEMO) {
  # Copy the read-only packaged dataset into a writable temporary project.
  demo_dir <- file.path(tempdir(), "howmahico_demo")
  unlink(demo_dir, recursive = TRUE)
  dir.create(demo_dir, recursive = TRUE)
  file.copy(system.file("extdata", "sim_fragpipe_dda", package = "HowMaHiCo"),
            demo_dir, recursive = TRUE)
  file.copy(system.file("extdata", "sim_fragpipe_dda_annotation.csv",
                        package = "HowMaHiCo"), demo_dir)

  CONFIG$SampleSet           <- "simulated_demo"
  CONFIG$Subset              <- ""
  CONFIG$Software            <- "fragpipe_dda_individual"
  CONFIG$FolderDocumentation <- demo_dir
  CONFIG$AnnotationFile      <- "sim_fragpipe_dda_annotation.csv"
  CONFIG$FolderData          <- file.path(demo_dir, "sim_fragpipe_dda")
  CONFIG$FolderResults       <- demo_dir
  CONFIG$FolderFigures       <- demo_dir
  CONFIG$ProjectDir          <- demo_dir

  message("Demo mode: working in ", demo_dir)
}


# ==============================================================================
# 2. Build the sample annotation table
# ==============================================================================
# The annotation csv maps each data folder to its experimental metadata. It
# controls TWO things beyond metadata:
#   * inclusion — only samples listed here are read and reported, so this is
#     also how you subset a run;
#   * ordering  — Conditions, replicates and samples appear in every plot and
#     table in the ROW ORDER of this csv.
#
# Step 2a generates a skeleton with one row per data file; you then fill in the
# experimental columns by hand. Skipped in demo mode, which ships a completed
# annotation table.

annot_path <- file.path(CONFIG$FolderDocumentation, CONFIG$AnnotationFile)

if (!RUN_DEMO && !file.exists(annot_path)) {
  # Pick the generator that matches your search engine:
  skeleton <- switch(
    sub("_.*", "", CONFIG$Software),
    fragpipe = get_annot_fragpipe(dir_data = CONFIG$FolderData),
    diann    = get_annot_diann(dir_data = CONFIG$FolderData),
    peaks    = get_annot_peaks(dir_data = CONFIG$FolderData),
    stop("No annotation generator for Software = ", CONFIG$Software)
  )

  # Optional: fill Sample_ID automatically from a Bruker HyStar sample list
  # instead of typing it. It joins on Source_file and warns when rows do not
  # match; keep_all = TRUE keeps unmatched annotation rows with an empty ID.
  #   skeleton <- get_annot_sampleid(skeleton,
  #                                  file_sample_list = "1_documentation/sample_list.xlsx",
  #                                  keep_all = TRUE)

  dir.create(CONFIG$FolderDocumentation, showWarnings = FALSE, recursive = TRUE)
  write.csv(skeleton, annot_path, row.names = FALSE)
  message("Annotation skeleton written to ", annot_path)
  message("Fill in Condition / BioReplicate / TechReplicate / Sample_ID, ",
          "put the rows in display order, save, then re-run this script.")
  stop("Annotation table needs to be completed before continuing.")
}

annot <- read_annot(annot_path)
print(annot)


# ==============================================================================
# 3. Preflight — check every file named in the annotation exists
# ==============================================================================
# A missing input otherwise surfaces much later as a confusing parse error.

expected <- if (grepl("fragpipe", CONFIG$Software)) {
  file.path(CONFIG$FolderData, annot$Sample_fp, "psm.tsv")
} else if (CONFIG$Software == "diann") {
  file.path(CONFIG$FolderData, annot$Sample_fp, "report.tsv")
} else if (CONFIG$Software == "peaks_xpro") {
  file.path(CONFIG$FolderData, annot$Sample_peaks)
} else {
  character(0)   # "custom": paths come from your dictionary
}

missing <- unique(expected[!file.exists(expected)])
if (length(missing) > 0) {
  message("Missing input files:")
  print(missing)
  stop("Files listed in the annotation table were not found. ",
       "Check FolderData and the Sample_folder column.")
}
message("Preflight OK: ", length(unique(expected)), " input file(s) found.")


# ==============================================================================
# 4. Parse once into the unified pep_all table
# ==============================================================================
# build_pep_all() runs the loader for your search engine and writes a cached
# <Subset>_pep_all.rda. Every focused report then renders against that cache,
# so the raw files are parsed once rather than once per report.

subset_prefix <- if (nzchar(CONFIG$Subset)) paste0(CONFIG$Subset, "_") else ""
file_rda <- file.path(CONFIG$FolderData, paste0(subset_prefix, "pep_all.rda"))

pep_all <- build_pep_all(
  software       = CONFIG$Software,
  folder_data    = CONFIG$FolderData,
  annotation     = annot,
  shortpep_range = mhc_length_window(CONFIG$MHCclass),
  instrument     = CONFIG$Instrument,
  test_mode      = FALSE,   # TRUE keeps ~100 rows per run, for a fast dry run
  file_rda       = file_rda
  # dictionary   = "my_tool.yaml"   # only when Software = "custom";
  #                                 # start from get_dictionary_template()
)

message("pep_all: ", nrow(pep_all), " rows, ",
        dplyr::n_distinct(pep_all$Peptide), " distinct peptides, cached at ", file_rda)


# ==============================================================================
# 5. Render the reports
# ==============================================================================
# Params shared by every report. Anything not listed keeps its template default.

report_params <- list(
  SampleSet           = CONFIG$SampleSet,
  Provider            = CONFIG$Provider,
  Subset              = CONFIG$Subset,
  FolderDocumentation = CONFIG$FolderDocumentation,
  AnnotationFile      = CONFIG$AnnotationFile,
  FolderData          = CONFIG$FolderData,
  FolderResults       = CONFIG$FolderResults,
  FolderFigures       = CONFIG$FolderFigures,
  ProjectDir          = CONFIG$ProjectDir,
  Software            = CONFIG$Software,
  Instrument          = CONFIG$Instrument,
  MHCclass            = CONFIG$MHCclass,
  ResultsOverwrite    = TRUE,   # FALSE aborts rather than overwrite earlier results
  PlotsSave           = FALSE,  # TRUE also writes every figure as png
  CsvSave             = FALSE   # TRUE also writes the intermediate csv tables
)

# --- 5a. The focused reports -------------------------------------------------
# Each renders one slice of the analysis against the cache from step 4. Render
# only the ones you need — they are independent.

focused <- c(
  "01_id_counts",     # identification counts, length/charge distributions, motifs, PTM profile
  "02_overlaps",      # replicate, cross-condition and pairwise overlap (UpSet plots)
  "03_lcms_qc",       # RT / ion mobility / m z distributions, Score and mass-error QC
  "04_quant",         # log2(Area) correlation between samples, Area %CV
  "05_quality_score", # per-sample immunopeptidomics quality score, traffic-light overview
  "06_quant_stats",   # differential abundance between Conditions (limma / Welch t)
  "07_pepchem"        # amino-acid composition, positional motifs, GRAVY and other descriptors
)

for (tmpl in focused) {
  message("Rendering ", tmpl, " ...")
  run_howmahico_report(
    template    = tmpl,
    params      = c(report_params, list(PepAllSource = "cached")),
    output_file = paste0(subset_prefix, tmpl, ".html"),
    quiet       = TRUE
  )
}

# --- 5b. The all-in-one report (optional) ------------------------------------
# 00_mhc_report covers most of the above in a single document and parses the raw
# files itself, so it does not use the cache (and ignores PepAllSource).
#
# run_howmahico_report(
#   template    = "00_mhc_report",
#   params      = report_params,
#   output_file = paste0(subset_prefix, "00_mhc_report.html"))


# ==============================================================================
# 6. Where the output went
# ==============================================================================
# <FolderResults>/<Subset>/
#   <Subset>_pep_all.csv                    the unified peptide table
#   <Subset>_counts_pep_all_condition.csv   identification counts per Condition
#   <Subset>_seq_by_condition.xlsx          peptide sequences per Condition
#   <Subset>_<report>_input_params.csv      every param used, for reproducibility
#   ... plus per-report result tables, and more when CsvSave = TRUE
# <FolderFigures>/<Subset>/                 png figures, when PlotsSave = TRUE
# The HTML reports are written next to ProjectDir.

message("Done. Results: ", CONFIG$FolderResults)
if (RUN_DEMO) {
  message("Demo outputs: ", demo_dir)
  print(list.files(demo_dir, pattern = "[.](html|csv|xlsx)$"))
}


# ==============================================================================
# 7. Optional: several subsets in one go
# ==============================================================================
# derive_filtered_annotation() writes a Condition-filtered copy of an annotation
# csv, which is how one experiment is split into per-group reports.
#
# for (grp in c("JY", "Plasma")) {
#   derive_filtered_annotation("sample_annotation.csv", "1_documentation", grp)
#   # then repeat steps 4-5 with AnnotationFile = "sample_annotation_jy.csv"
#   # and Subset = "jy", etc.
# }
