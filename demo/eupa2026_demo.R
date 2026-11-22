# =============================================================================
# HowMaHiCo — EuPA 2026 demonstration
# -----------------------------------------------------------------------------
# Reproduces the figures and numbers behind the abstract's Results paragraph,
# from SIMULATED data (MaHiCoInSilico; not the real JY data, which is still to
# come):
#
#   * class 1: example/2_data/sim_fragpipe_dda_hla1  (HLA-A*02:01 + B*07:02)
#   * class 2: example/2_data/sim_fragpipe_dda_hla2  (HLA-DRB1*01:01)
#   * simulated here, all as FragPipe DDA psm.tsv with the same CTRL/TREAT x 3
#     design:
#       - a contamination titration: the class-1 pulldown blended with tryptic
#         whole-proteome peptides at p = 0 ... 1 (p = 1 is a failed pulldown,
#         i.e. the whole-proteome negative control)
#       - cross-class contamination: the class-1 pulldown + 25 % class 2
#
# Then it builds pep_all for every run, renders the reports, and stacks the
# quality scores with compare_runs() into the poster panels.
#
# Run from the repository root:   Rscript demo/eupa2026_demo.R
# Needs: HowMaHiCo (this repo, installed or via devtools::load_all()),
#        MaHiCoInSilico (only when a simulated folder does not exist yet), pandoc.
# Data and outputs live under example/, which is gitignored. Re-running skips
# simulations whose folders already exist.
# =============================================================================

if (requireNamespace("devtools", quietly = TRUE) && file.exists("DESCRIPTION")) {
  devtools::load_all(quiet = TRUE)
} else {
  library(HowMaHiCo)
}

# ---- 0. Config ---------------------------------------------------------------
PROJECT_DIR <- normalizePath(".")   # the repo root; all paths below are relative to it
ROOT        <- "example"
DIR_DATA    <- file.path(ROOT, "2_data")
DIR_DOC     <- file.path(ROOT, "1_documentation")
DIR_RESULTS <- file.path(ROOT, "3_results", "eupa2026")
DIR_FIGURES <- file.path(ROOT, "4_figures", "eupa2026")
DIR_HTML    <- file.path(DIR_RESULTS, "html")
SAMPLE_SET  <- "EuPA2026 demo"

SEED <- 1
# Limit of detection for the mixed runs. With lod = 0 every spike peptide is
# "detected" whatever its share, so counts would not move along the titration;
# at 1e6 (simulated intensities have a log10 mean of 6) the per-sample share of
# tryptic peptides tracks the blend proportion p closely (checked: p = 0.25 ->
# ~0.29, p = 0.5 -> ~0.50, p = 0.75 -> ~0.71), at ~2,100-2,700 peptides/sample.
LOD <- 1e6
TITRATION <- c(0, 0.05, 0.10, 0.25, 0.50, 0.75, 1)

HOST_HLA1 <- list(n = 5000, mhc_class = "MHC1",
                  alleles = c("HLA-A*02:01", "HLA-B*07:02"), seed = 1)
SPIKE_PROTEOME <- list(n = 5000, data_type = "proteomics", seed = 2)
SPIKE_HLA2 <- list(n = 5000, mhc_class = "MHC2", alleles = "HLA-DRB1*01:01", seed = 1)
DESIGN <- list(conditions = c("CTRL", "TREAT"), n_bioreps = 3)

for (d in c(DIR_RESULTS, DIR_FIGURES, DIR_HTML)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

# every run: name, data folder, annotation csv, MHC class it is scored as
run_name <- function(p) sprintf("titr_p%03d", round(100 * p))
runs <- rbind(
  data.frame(run = c("hla1", "hla2"),
             folder = c("sim_fragpipe_dda_hla1", "sim_fragpipe_dda_hla2"),
             annotation = c("sim_fragpipe_dda_hla1.csv", "sim_fragpipe_dda_hla2.csv"),
             mhcclass = c("MHC1", "MHC2"), proportion = NA_real_, kind = "given",
             stringsAsFactors = FALSE),
  data.frame(run = run_name(TITRATION),
             folder = paste0("sim_fragpipe_dda_", run_name(TITRATION)),
             annotation = paste0("sim_fragpipe_dda_", run_name(TITRATION), ".csv"),
             mhcclass = "MHC1", proportion = TITRATION, kind = "titration",
             stringsAsFactors = FALSE),
  data.frame(run = "cross_hla2_p025", folder = "sim_fragpipe_dda_cross_hla2_p025",
             annotation = "sim_fragpipe_dda_cross_hla2_p025.csv",
             mhcclass = "MHC1", proportion = 0.25, kind = "cross_class",
             stringsAsFactors = FALSE)
)

# ---- 1. Simulate the controls -----------------------------------------------
simulate_mix <- function(folder, annotation, spike, p) {
  out_dir <- file.path(DIR_DATA, folder)
  if (dir.exists(out_dir)) {
    message("exists, skipping simulation: ", out_dir)
    return(invisible())
  }
  if (!requireNamespace("MaHiCoInSilico", quietly = TRUE))
    stop("MaHiCoInSilico is needed to simulate '", folder, "'.")
  message("simulating ", folder, " (p = ", p, ")")
  ex <- do.call(MaHiCoInSilico::mix_experiment,
                c(list(tool = "fragpipe", results_dir = out_dir,
                       host = HOST_HLA1, spike = spike, proportion = p,
                       mode = "blend", lod = LOD, seed = SEED), DESIGN))
  file.copy(ex$annotation_path, file.path(DIR_DOC, annotation), overwrite = TRUE)
}

for (i in which(runs$kind == "titration"))
  simulate_mix(runs$folder[i], runs$annotation[i], SPIKE_PROTEOME, runs$proportion[i])
i <- which(runs$kind == "cross_class")
simulate_mix(runs$folder[i], runs$annotation[i], SPIKE_HLA2, runs$proportion[i])

# ---- 2. Build pep_all and render the reports --------------------------------
all_reports <- c("01_mhc_overview", "02_prot_all", "03_lcms_qc",
                 "04_pepchem", "05_quant_stats")
# the control runs only need the quality score and red flags, both in 01
control_reports <- "01_mhc_overview"

for (i in seq_len(nrow(runs))) {
  r <- runs[i, ]
  message("\n==== ", r$run, " (scored as ", r$mhcclass, ") ====")
  file_rda <- file.path(DIR_DATA, paste0(r$run, "_pep_all.rda"))
  annot <- read_annot(file.path(DIR_DOC, r$annotation))
  suppressWarnings(build_pep_all("fragpipe_dda_individual",
                                 folder_data = file.path(DIR_DATA, r$folder),
                                 annotation = annot,
                                 shortpep_range = mhc_length_window(r$mhcclass),
                                 file_rda = file_rda))

  reports <- if (r$kind == "given") all_reports else control_reports
  for (tmpl in reports) {
    message("  rendering ", tmpl)
    run_howmahico_report(
      tmpl,
      params = list(SampleSet = SAMPLE_SET, Subset = r$run,
                    FolderDocumentation = DIR_DOC, AnnotationFile = r$annotation,
                    FolderData = DIR_DATA, FolderResults = DIR_RESULTS,
                    FolderFigures = DIR_FIGURES, PepAllSource = "cached",
                    Software = "fragpipe_dda_individual", Instrument = "tims_tof",
                    MHCclass = r$mhcclass, ResultsOverwrite = TRUE,
                    # the report knits from the template's own folder unless a
                    # project root is given; this makes the relative paths
                    # above (and output_file) resolve against the repo root
                    ProjectDir = PROJECT_DIR),
      output_file = file.path(DIR_HTML, paste0(r$run, "__", tmpl, ".html")),
      quiet = TRUE)
  }
}

# ---- 3. Poster panels --------------------------------------------------------
results_of <- function(run) file.path(DIR_RESULTS, run)
pct <- function(p) paste0(round(100 * p), "% tryptic")

# Panel A: the titration, from a clean class-1 pulldown (0 %) to a failed one
# (100 % tryptic whole-proteome peptides). All scored as MHC1.
titr <- runs[runs$kind == "titration", ]
runs_titr <- compare_runs(stats::setNames(results_of(titr$run), pct(titr$proportion)))
p_titration <- plot_run_trend(
  runs_titr,
  metrics = c("composite_score", "frac_in_window", "frac_cterm_KR_longonly",
              "anchor_information"),
  type = "line") +
  ggplot2::guides(shape = "none") +   # no QC samples in this design
  ggplot2::ggtitle("How MHC is the dataset? Class-1 pulldown blended with tryptic peptides")
ggplot2::ggsave(file.path(DIR_FIGURES, "panel_A_titration.png"), p_titration,
                width = 10, height = 6, dpi = 300)

# Panel B: the two given classes, cross-class contamination and the failed
# pulldown. hla2 is scored as MHC2 and the rest as MHC1, so compare_runs()
# warns that the composite scores were computed with different thresholds -
# expected here: each run is scored as the pulldown it claims to be.
labels_b <- c(hla1 = "Class 1 (MHC1)", hla2 = "Class 2 (MHC2)",
              cross_hla2_p025 = "Class 1 + 25% class 2",
              titr_p100 = "Failed pulldown (proteome)")
runs_b <- suppressWarnings(compare_runs(stats::setNames(results_of(names(labels_b)), labels_b)))
p_classes <- plot_run_trend(runs_b,
                            metrics = c("composite_score", "frac_in_window",
                                        "frac_cross_class"),
                            type = "box", color_by = "Condition") +
  ggplot2::guides(shape = "none") +
  ggplot2::ggtitle("Genuine class 1 and class 2 immunopeptidomes vs. contaminated and failed pulldowns")
ggplot2::ggsave(file.path(DIR_FIGURES, "panel_B_classes.png"), p_classes,
                width = 10, height = 5, dpi = 300)

# ---- 4. Numbers for the Results paragraph -----------------------------------
runs_all <- suppressWarnings(compare_runs(stats::setNames(results_of(runs$run), runs$run)))
summary_tbl <- summarise_runs(runs_all,
                              metrics = c("composite_score", "frac_in_window",
                                          "frac_cterm_KR_longonly", "anchor_information",
                                          "frac_nested_core", "frac_cross_class",
                                          "n_unique_pep", "n_unique_pep_in_window"))
utils::write.csv(summary_tbl, file.path(DIR_RESULTS, "runs_summary.csv"), row.names = FALSE)
utils::write.csv(runs_all, file.path(DIR_RESULTS, "runs_scores_stacked.csv"), row.names = FALSE)

med <- function(run, metric) {
  v <- summary_tbl$median[summary_tbl$Run == run & summary_tbl$metric == metric]
  if (length(v) == 0 || is.na(v)) "NA" else format(signif(v, 3))
}
cats <- function(run) {
  x <- summary_tbl[summary_tbl$Run == run, ][1, ]
  sprintf("%d Pass / %d Warning / %d Fail", x$n_Pass, x$n_Warning, x$n_Fail)
}
lines <- c(
  "# EuPA 2026 demonstration — numbers (simulated data)",
  "",
  paste0("Generated by `demo/eupa2026_demo.R` on ", Sys.Date(), " with HowMaHiCo ",
         utils::packageVersion("HowMaHiCo"), ". LOD for the mixed runs: ", format(LOD), "."),
  "",
  "| Run | Scored as | Median composite | Samples | Median unique peptides | in window | Length in window | Tryptic background | Cross-class |",
  "|---|---|---|---|---|---|---|---|---|",
  vapply(seq_len(nrow(runs)), function(i) {
    r <- runs$run[i]
    sprintf("| %s | %s | %s | %s | %s | %s | %s | %s | %s |", r, runs$mhcclass[i],
            med(r, "composite_score"), cats(r), med(r, "n_unique_pep"),
            med(r, "n_unique_pep_in_window"), med(r, "frac_in_window"),
            med(r, "frac_cterm_KR_longonly"), med(r, "frac_cross_class"))
  }, character(1)),
  "",
  "## Caveats",
  "",
  "* **Simulated data** (MaHiCoInSilico): not the real JY class 1/class 2 data, which is still to come.",
  "* **Class 2 is a lower bound.** The simulator draws class-II peptides independently, so it never",
  "  produces the ragged nested families of a real HLA-II immunopeptidome: `frac_nested_core` is ~0",
  "  and that weight-3 dimension scores 0. A genuine class-II sample would score higher.",
  "* **Anchor motif clarity rebounds at 100 % tryptic**: pure tryptic 9-mers all end in K/R, which",
  "  looks like a sharp PΩ anchor. The composite still falls monotonically because the length,",
  "  tryptic-background and cross-class dimensions dominate. Flagged for review in plans_dgz.",
  "",
  "Figures: `example/4_figures/eupa2026/panel_A_titration.png`, `panel_B_classes.png`.",
  "Per-run reports: `example/3_results/eupa2026/html/`."
)
writeLines(lines, file.path(DIR_RESULTS, "demo_summary.md"))
message("\nDone. Summary: ", file.path(DIR_RESULTS, "demo_summary.md"))
