# Pure-math checks of the scoring curve and helpers. These need no synthetic
# peptide data; numeric/behavioural validation of the full scorer against real
# or simulated immunopeptidomics datasets is done separately.

test_that("score_curve hits its anchor points (higher_better)", {
  expect_equal(score_curve(0.80, green = 0.80, amber = 0.60, "higher_better"), 100)
  expect_equal(score_curve(0.60, green = 0.80, amber = 0.60, "higher_better"), 50)
  expect_equal(score_curve(0.90, green = 0.80, amber = 0.60, "higher_better"), 100) # clamped
  expect_equal(score_curve(0.20, green = 0.80, amber = 0.60, "higher_better"), 0)   # clamped
})

test_that("score_curve hits its anchor points (lower_better)", {
  expect_equal(score_curve(5,  green = 5, amber = 10, "lower_better"), 100)
  expect_equal(score_curve(10, green = 5, amber = 10, "lower_better"), 50)
  expect_equal(score_curve(2,  green = 5, amber = 10, "lower_better"), 100) # clamped
  expect_equal(score_curve(20, green = 5, amber = 10, "lower_better"), 0)   # clamped
})

test_that("score_curve returns NA when value or threshold is missing", {
  expect_true(is.na(score_curve(NA, green = 0.8, amber = 0.6, "higher_better")))
  expect_true(is.na(score_curve(0.7, green = NA, amber = 0.6, "higher_better")))
  expect_true(is.na(score_curve(0.7, green = 0.8, amber = NA, "higher_better")))
})

test_that("anchor_information_content is high for a fixed anchor, ~0 for noise", {
  set.seed(1)
  aa <- c("A", "R", "N", "D", "C", "Q", "E", "G", "H", "I",
          "L", "K", "M", "F", "P", "S", "T", "W", "Y", "V")
  # P2 = L and P9 = V fixed; other positions random -> high information at anchors
  anchored <- vapply(1:200, function(i) {
    paste0(sample(aa, 1), "L", paste(sample(aa, 6, TRUE), collapse = ""), "V")
  }, character(1))
  # fully random -> near-zero information everywhere
  noise <- vapply(1:200, function(i) paste(sample(aa, 9, TRUE), collapse = ""), character(1))

  expect_gt(anchor_information_content(anchored), 6)        # near 2*log2(20)
  expect_lt(anchor_information_content(noise), 1)
  expect_true(is.na(anchor_information_content(character(0))))
  expect_true(is.na(anchor_information_content(rep("SLFIGLKEV", 3)))) # below min_n
})

test_that("quality_thresholds_default is well formed", {
  th <- quality_thresholds_default()
  expect_true(all(c("metric", "label", "direction", "green", "amber", "weight") %in% names(th)))
  expect_true(all(th$direction %in% c("higher_better", "lower_better")))
  expect_true("frac_cross_class" %in% th$metric)
})

test_that(".cross_class_range picks the other class's outside-window tail", {
  # MHC1 (8-13): cross region is the MHC2 tail above the window
  expect_equal(HowMaHiCo:::.cross_class_range("MHC1", c(8, 13)), c(14, 25))
  # MHC2 (12-25): cross region is the MHC1 tail below the window
  expect_equal(HowMaHiCo:::.cross_class_range("MHC2", c(12, 25)), c(8, 11))
  # custom / unknown class -> undefined
  expect_null(HowMaHiCo:::.cross_class_range("custom", c(7, 20)))
})

test_that("qc_metrics_by_sample computes frac_cross_class for an MHC1 sample", {
  pep <- data.frame(
    Sample = factor(rep("S1", 6)),
    Peptide = paste0("PEP", 1:6),
    Sequence = paste0("PEP", 1:6),
    Length = c(9L, 9L, 10L, 11L, 15L, 16L),  # two peptides (15,16) in the MHC2 tail
    Cter = c("V", "L", "K", "A", "R", "Y"),
    Charge = c(2, 2, 1, 2, 3, 2),
    Accession = paste0("ACC", 1:6),
    ppm = c(1, -2, 3, -1, 2, -3),
    stringsAsFactors = FALSE
  )
  m <- qc_metrics_by_sample(pep, shortpep_range = c(8, 13), mhcclass = "MHC1")
  expect_equal(m$frac_cross_class, 2 / 6)

  # undefined for a custom (non-MHC1/MHC2) window
  m_custom <- qc_metrics_by_sample(pep, shortpep_range = c(7, 20), mhcclass = "custom")
  expect_true(is.na(m_custom$frac_cross_class))
})

# ---- murine MHC-I (MHCclass = "MHC1_mouse") ---------------------------------

# H-2 ligands are shorter than HLA-I ones (7-11 AAs) and peak at BOTH 8- and
# 9-mers (H-2Kb favours 8-mers, H-2Db 9-mers), so the canonical-length metric
# must count two lengths there instead of 9-mers only.
make_mouse_pep_all <- function(n_8 = 12, n_9 = 8, n_long = 5) {
  set.seed(42)
  aa <- c("A", "L", "V", "F", "I", "S", "T", "N", "Q", "Y")
  seq_of <- function(k) paste(sample(aa, k, replace = TRUE), collapse = "")
  seqs <- c(vapply(seq_len(n_8), function(i) paste0("S", seq_of(6), "L"), character(1)),
            vapply(seq_len(n_9), function(i) paste0("A", seq_of(7), "V"), character(1)),
            vapply(seq_len(n_long), function(i) seq_of(16), character(1)))
  data.frame(Sample = factor("M1"), Peptide = seqs, Sequence = seqs,
             Length = nchar(seqs), Accession = "P1",
             Charge = factor("+ 2", levels = c("+ 1", "+ 2", "+ 3")),
             Cter = substr(seqs, nchar(seqs), nchar(seqs)),
             ppm = 1, stringsAsFactors = FALSE)
}

test_that("qc_metrics_by_sample counts 8- and 9-mers for MHC1_mouse", {
  pep <- make_mouse_pep_all()

  mouse <- qc_metrics_by_sample(pep, shortpep_range = c(7, 11), mhcclass = "MHC1_mouse")
  human <- qc_metrics_by_sample(pep, shortpep_range = c(8, 13), mhcclass = "MHC1")

  n_tot <- nrow(pep)
  expect_equal(mouse$frac_9mer, (12 + 8) / n_tot)   # 8-mers AND 9-mers
  expect_equal(human$frac_9mer, 8 / n_tot)          # 9-mers only
  # the anchor metric stays defined for mouse (scored on the modal canonical length)
  expect_false(is.na(mouse$anchor_information))
})

test_that("the cross-class window follows the mouse MHC-I window", {
  expect_equal(HowMaHiCo:::.cross_class_range("MHC1_mouse", c(7, 11)), c(12, 25))
  expect_equal(HowMaHiCo:::.cross_class_range("MHC1", c(8, 13)), c(14, 25))
  expect_null(HowMaHiCo:::.cross_class_range("custom", c(9, 11)))
})

test_that("quality_thresholds_default relabels and raises the mouse canonical-length row", {
  human <- quality_thresholds_default()
  mouse <- quality_thresholds_default("MHC1_mouse")

  expect_equal(human$metric, mouse$metric)          # data keys unchanged
  i <- match("frac_9mer", mouse$metric)
  expect_equal(mouse$label[i], "8/9-mer fraction")
  expect_gt(mouse$green[i], human$green[i])
  expect_gt(mouse$amber[i], human$amber[i])
})

test_that("score_sample_quality picks up the class-appropriate thresholds", {
  pep <- make_mouse_pep_all()
  scores <- score_sample_quality(pep, shortpep_range = c(7, 11), mhcclass = "MHC1_mouse")

  expect_equal(nrow(scores), 1L)
  expect_true(is.finite(scores$composite_score))
  expect_true(scores$composite_score >= 0 && scores$composite_score <= 100)
})

# frac_nested_core (v0.20.0) is the class-II substitute for anchor-motif clarity:
# MHC-II ligands are trimmed into ragged families around one ~9-mer core, so the
# share of ligands sharing a 9-mer with another ligand separates a real HLA-II
# immunopeptidome from a background set -- with no alignment or register guess.

test_that(".nested_core_fraction finds shared cores and ignores internal repeats", {
  nested <- c("AAKFVGITKLVTRPL", "KFVGITKLVTRPLSE", "GITKLVTRPLSEDPP")
  expect_equal(HowMaHiCo:::.nested_core_fraction(nested), 1)

  # same residue repeated: plenty of identical k-mers WITHIN each sequence, none
  # shared BETWEEN them, so a sequence must not count as nested with itself
  disjoint <- c("AAAAAAAAAAAA", "CCCCCCCCCCCC", "DDDDDDDDDDDD")
  expect_equal(HowMaHiCo:::.nested_core_fraction(disjoint), 0)

  expect_equal(HowMaHiCo:::.nested_core_fraction(c(nested, disjoint)), 0.5)
})

test_that(".nested_core_fraction is NA when there is nothing to compare", {
  expect_true(is.na(HowMaHiCo:::.nested_core_fraction(character(0))))
  expect_true(is.na(HowMaHiCo:::.nested_core_fraction("SLFIGLKEV")))        # one sequence
  expect_true(is.na(HowMaHiCo:::.nested_core_fraction(c("SHORT", "ALSO"))))  # all < k
  # duplicates are one sequence
  expect_true(is.na(HowMaHiCo:::.nested_core_fraction(c("AAKFVGITKLV", "AAKFVGITKLV"))))
})

test_that("MHC2 promotes frac_nested_core to the motif dimension", {
  human <- quality_thresholds_default("MHC1")
  mouse <- quality_thresholds_default("MHC1_mouse")
  cls2  <- quality_thresholds_default("MHC2")

  # data keys unchanged across classes (only labels/cut-offs/weights move)
  expect_equal(human$metric, cls2$metric)
  expect_equal(human$metric, mouse$metric)

  i <- match("frac_nested_core", cls2$metric)
  expect_equal(human$weight[i], 0)                      # MHC-I: diagnostic only
  expect_equal(mouse$weight[i], 0)
  expect_equal(cls2$weight[i],                           # MHC-II: the anchor's weight
               cls2$weight[match("anchor_information", cls2$metric)])
  expect_equal(cls2$label[i], "Nested-core families")
  expect_gt(cls2$green[i], cls2$amber[i])                # higher_better
})

# DIA calibration accuracy (v0.20.0): DIA-NN reports no observed precursor m/z,
# so its ppm is a dummy and no real mass error can be derived from report.tsv.
# Its predicted RT/IM are the analogue, and they are absent for FragPipe/PEAKS.

test_that(".median_abs_delta guards absent and placeholder columns", {
  expect_equal(HowMaHiCo:::.median_abs_delta(c(10, 12), c(10.4, 12.2)), 0.3)
  expect_true(is.na(HowMaHiCo:::.median_abs_delta(c(1, 2), NULL)))
  expect_true(is.na(HowMaHiCo:::.median_abs_delta(NULL, c(1, 2))))
  # an all-zero difference is a placeholder, not perfect accuracy
  expect_true(is.na(HowMaHiCo:::.median_abs_delta(c(1, 2), c(1, 2))))
  expect_true(is.na(HowMaHiCo:::.median_abs_delta(c(NA, NA), c(1, 2))))
  expect_equal(HowMaHiCo:::.median_abs_delta(c(1, NA, 5), c(1.5, 2, 4)), 0.75)
})

test_that("calibration metrics are NA without predictions and populated with them", {
  pep <- make_mouse_pep_all()
  m_dda <- qc_metrics_by_sample(pep, shortpep_range = c(7, 11), mhcclass = "MHC1_mouse")
  expect_true(is.na(m_dda$median_abs_rt_error))
  expect_true(is.na(m_dda$median_abs_im_error))

  pep_dia <- pep
  pep_dia$RT <- seq_len(nrow(pep)) / 10
  pep_dia$Predicted.RT <- pep_dia$RT + 0.2
  pep_dia$invk0 <- 0.9
  pep_dia$Predicted.IM <- 0.91
  m_dia <- qc_metrics_by_sample(pep_dia, shortpep_range = c(7, 11), mhcclass = "MHC1_mouse")
  expect_equal(m_dia$median_abs_rt_error, 0.2, tolerance = 1e-8)
  expect_equal(m_dia$median_abs_im_error, 0.01, tolerance = 1e-8)
})

test_that("every scored metric exists in the metrics table (composite would error otherwise)", {
  # score_sample_quality() subsets scores[, paste0("score_", scored_metrics)],
  # so a threshold row whose metric never reaches qc_metrics_by_sample() would
  # abort the whole report
  pep <- make_mouse_pep_all()
  for (cls in mhc_classes()) {
    win <- mhc_length_window(cls)
    m <- qc_metrics_by_sample(pep, shortpep_range = win, mhcclass = cls)
    th <- quality_thresholds_default(cls)
    expect_equal(setdiff(th$metric, names(m)), character(0), info = cls)
    expect_silent(s <- score_sample_quality(pep, shortpep_range = win, mhcclass = cls))
    expect_true(is.na(s$composite_score) || (s$composite_score >= 0 && s$composite_score <= 100))
  }
})

# ---- class-aware charge plausibility (v0.26.0) -------------------------------

test_that("frac_charge_1_2 counts 1+/2+ for MHC1 but 2+ to 4+ for MHC2", {
  seqs <- c("AAAAAAAAAAAAAK", "CCCCCCCCCCCCCK", "DDDDDDDDDDDDDK",
            "EEEEEEEEEEEEEK", "FFFFFFFFFFFFFK")            # all 14-mers
  pep <- data.frame(Sample = factor("S1"), Peptide = seqs, Sequence = seqs,
                    Length = nchar(seqs), Cter = "K", Accession = "P1",
                    Charge = factor(c("+ 2", "+ 3", "+ 3", "+ 4", "+ 5")),
                    stringsAsFactors = FALSE)
  m2 <- qc_metrics_by_sample(pep, shortpep_range = c(12, 25), mhcclass = "MHC2")
  expect_equal(m2$frac_charge_1_2, 4 / 5)                  # 2+, 3+, 3+, 4+
  m1 <- qc_metrics_by_sample(pep, shortpep_range = c(12, 25), mhcclass = "MHC1")
  expect_equal(m1$frac_charge_1_2, 1 / 5)                  # only the 2+
})

test_that("the charge metric is not fooled by a factor without a 1+ level", {
  # level codes of c("+ 2", "+ 3") are 1 and 2, which used to count as 1+/2+
  seqs <- c("AAAAAAAAV", "CCCCCCCCV", "DDDDDDDDV", "EEEEEEEEV")
  pep <- data.frame(Sample = factor("S1"), Peptide = seqs, Sequence = seqs,
                    Length = 9L, Cter = "V", Accession = "P1",
                    Charge = factor(c("+ 2", "+ 3", "+ 3", "+ 3")),
                    stringsAsFactors = FALSE)
  m <- qc_metrics_by_sample(pep, shortpep_range = c(8, 13), mhcclass = "MHC1")
  expect_equal(m$frac_charge_1_2, 1 / 4)
})

test_that("MHC2 relabels the charge row with its own cut-offs; MHC1 is unchanged", {
  th1 <- quality_thresholds_default("MHC1")
  th2 <- quality_thresholds_default("MHC2")
  r1 <- th1[th1$metric == "frac_charge_1_2", ]
  r2 <- th2[th2$metric == "frac_charge_1_2", ]
  expect_equal(r1$label, "Charge 1+/2+")
  expect_equal(c(r1$green, r1$amber), c(0.85, 0.70))
  expect_equal(r2$label, "Charge 2+ to 4+")
  expect_equal(c(r2$green, r2$amber), c(0.80, 0.60))
  expect_equal(r2$weight, r1$weight)
})

test_that("plot_quality_heatmap() omits metrics that are NA for every sample", {
  sc <- data.frame(Sample = factor(c("S1", "S2")), is_QC = FALSE,
                   score_frac_in_window = c(90, 60),
                   score_median_abs_rt_error = c(NA_real_, NA_real_),
                   score_median_abs_ppm = c(80, NA))
  th <- quality_thresholds_default()
  lab <- function(m) th$label[th$metric == m]
  shown <- levels(droplevels(plot_quality_heatmap(sc, th)$data$Metric))
  expect_false(lab("median_abs_rt_error") %in% shown)
  expect_true(all(c(lab("frac_in_window"), lab("median_abs_ppm")) %in% shown))
  kept <- levels(droplevels(plot_quality_heatmap(sc, th, drop_all_na = FALSE)$data$Metric))
  expect_true(lab("median_abs_rt_error") %in% kept)
})
