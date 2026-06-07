# Smoke tests: every plotting function returns a ggplot/ggarrange ("gg"-class)
# object without erroring when fed `pep_all`-shaped synthetic data and the
# tables its companion counting helpers produce. These intentionally don't
# render/print the plots (slow, display-dependent) -- just confirm the
# function builds its layers/grobs successfully end to end.

test_that("plot_peplength and plot_peplength_dens build boxplot-over-histogram figures", {
  pep_all <- make_pep_all()
  expect_s3_class(plot_peplength(pep_all, title = "All peptides"), "gg")
  expect_s3_class(plot_peplength_dens(pep_all, title = "All peptides"), "gg")
})

test_that("plot_pepmass and plot_pepmz build apex-annotated mass/m_z distribution figures", {
  pep_all <- make_pep_all()
  expect_s3_class(plot_pepmass(pep_all, title = "All peptides"), "gg")
  expect_s3_class(plot_pepmz(pep_all, title = "All peptides"), "gg")
})

test_that("plot_bp_count_length builds a stacked-by-Length_range bar chart from a counts_size_total-shaped table", {
  # plot_bp_count_length expects the wide `counts_size_total` shape built inline
  # in the legacy Rmd (Condition/Length_range/n_<level> + an "All peptides" total
  # row per Condition) -- NOT count_ids_condition_bylengthrange()'s long-format
  # pivoted output (Level/Count/Proportion), which is a different table entirely.
  counts <- data.frame(
    Condition = factor(rep(c("JY_tissue", "JY_plasma"), each = 2),
                       levels = c("JY_tissue", "JY_plasma")),
    Length_range = factor(rep(c("All peptides", "8 to 13 AAs"), times = 2),
                          levels = c("All peptides", "others", "8 to 13 AAs")),
    n_Peptides = c(10L, 8L, 12L, 9L)
  )
  expect_s3_class(plot_bp_count_length(counts, "Peptides", lim_level = 50), "gg")
})

test_that("plot_venn4 builds a Venn diagram of a grouped variable (<= 4 groups)", {
  pep_all <- make_pep_all()
  expect_s3_class(plot_venn4(pep_all, "Sequence", "Condition"), "gg")
})

test_that("plot_upset and plot_upset_batch build UpSet intersection plots", {
  pep_all <- make_pep_all()
  expect_s3_class(plot_upset(pep_all, Sequence, Compare = "Condition"), "gg")

  batch <- plot_upset_batch(pep_all, c("Peptide", "Sequence"), Compare = "Condition")
  expect_type(batch, "list")
  expect_setequal(names(batch), c("Peptide_by_Condition", "Sequence_by_Condition"))
  expect_true(all(vapply(batch, inherits, logical(1), what = "gg")))
})

test_that("ggseqlogo_bylength builds a per-group motif logo for a given peptide length", {
  pep_all <- make_pep_all()
  # Length == 9 sequences (AAAVAAAAL/GILGFVFTL) appear in all three Conditions
  expect_s3_class(ggseqlogo_bylength(pep_all, seq_length = 9, by = "Condition"), "gg")
})

test_that("ggseqlogo_bylength prints about groups dropped for lacking sequences of the requested length", {
  pep_all <- make_pep_all()
  # Length == 8 (SIINFEKL) only appears in JY_plasma -- JY_tissue/MM_plasma get dropped.
  # The notice is emitted via print(), not message(), so check stdout, not the
  # message condition.
  expect_output(ggseqlogo_bylength(pep_all, seq_length = 8, by = "Condition"), "were droped")
})

test_that("plot_prop_length_condition builds a stacked Length_range proportion bar chart", {
  pep_all <- make_pep_all()
  counts <- count_ids_condition_bylengthrange(pep_all)
  expect_s3_class(plot_prop_length_condition(counts), "gg")
})

test_that("plot_charge_proportions builds a stacked charge-state proportion bar chart", {
  count_table <- make_count_charge_table()
  proportions <- get_proportion_charge(count_table)
  expect_s3_class(plot_charge_proportions(proportions, Condition), "gg")
})

test_that("plot_violin_areacv builds a violin/boxplot of Area %CV by group", {
  pep_all <- make_pep_all()
  areacv <- summarise_area(pep_all, Condition)
  expect_s3_class(plot_violin_areacv(areacv, Condition), "gg")
})

test_that("plot_corr builds a correlation heatmap from a correlation matrix", {
  pep_all <- make_pep_all()
  mat <- get_mat_log2area(pep_all, PeptideID, Sample)
  corr_mat <- stats::cor(mat, method = "pearson", use = "pairwise.complete.obs")
  expect_s3_class(plot_corr(corr_mat), "gg")
})

test_that("plot_heatmap clusters a Log2Area matrix and writes a png", {
  old_wd <- getwd()
  dir <- "plot_heatmap_test"
  setwd(tempdir())
  on.exit({ unlink(dir, recursive = TRUE); setwd(old_wd) })
  dir.create(dir)

  # plot_heatmap's bins_palette <- diff(range(mat)) needs a finite range, but
  # get_mat_log2area()'s pivoted output on the small synthetic pep_all is sparse
  # (most PeptideIDs are observed in only one or two Samples, so most cells are
  # NA and range(mat) is NA) -- hand-build a small, complete (NA-free) matrix
  # whose column names match make_annot()'s Sample levels instead.
  annot <- make_annot()
  samples <- levels(annot$Sample)
  set.seed(1)
  mat <- matrix(stats::rnorm(6 * length(samples), mean = 12, sd = 1.5),
                nrow = 6, dimnames = list(paste0("Pep", 1:6), samples))
  file <- file.path(dir, "hm_test.png")

  expect_message(plot_heatmap(mat, annot, level = "Sample", group = "Condition", file = file),
                 "Heatmap saved")
  expect_true(file.exists(file))
})
