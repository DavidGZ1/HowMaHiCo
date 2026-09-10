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
