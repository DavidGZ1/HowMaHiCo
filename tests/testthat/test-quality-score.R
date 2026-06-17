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
})
