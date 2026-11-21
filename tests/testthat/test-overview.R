# overview_red_flags() and qc_samples_from_annotation(): the logic behind the
# 01_mhc_overview report's "Red flags" section (formerly 09_overview) and the shared QC-sample lookup.

# a score table in score_sample_quality()'s shape; every sample clean by default
flag_scores <- function(n = 4, ...) {
  df <- data.frame(Sample = factor(paste0("s", seq_len(n)), levels = paste0("s", seq_len(n))),
                   frac_in_window = rep(0.9, n), score_frac_in_window = rep(100, n),
                   frac_cross_class = rep(0.01, n), score_frac_cross_class = rep(100, n),
                   n_unique_pep = rep(1000, n),
                   composite_score = rep(90, n),
                   stringsAsFactors = FALSE)
  mods <- list(...)
  for (nm in names(mods)) df[[nm]] <- mods[[nm]]
  df$category <- factor(ifelse(df$composite_score >= 70, "Pass",
                               ifelse(df$composite_score >= 40, "Warning", "Fail")),
                        levels = c("Pass", "Warning", "Fail"))
  df
}

test_that("a clean experiment raises no flags and returns the right empty shape", {
  out <- overview_red_flags(flag_scores())
  expect_equal(nrow(out), 0L)
  expect_named(out, c("Sample", "Severity", "Flag", "Detail"))
  expect_equal(levels(out$Severity), c("High", "Medium", "Low"))
})

test_that("composite categories map to High (Fail) and Medium (Warning)", {
  out <- overview_red_flags(flag_scores(composite_score = c(90, 55, 20, 90)))
  expect_equal(as.character(out$Sample), c("s3", "s2"))
  expect_equal(as.character(out$Severity), c("High", "Medium"))
  expect_match(out$Detail[1], "below 40")
})

test_that("a scored dimension past amber is flagged with its label; weight-0 ones are not", {
  sc <- flag_scores(frac_cross_class = c(0.01, 0.20, 0.01, 0.01),
                    score_frac_cross_class = c(100, 30, 100, 100),
                    frac_in_window = c(0.9, 0.9, 0.3, 0.9),
                    score_frac_in_window = c(100, 100, 0, 100))
  out <- overview_red_flags(sc)
  expect_true(any(out$Sample == "s2" & out$Flag == "Cross-class contamination" &
                    out$Severity == "Medium"))
  expect_true(any(out$Sample == "s3" & out$Flag == "Length in window" &
                    out$Severity == "High"))
  expect_match(out$Detail[out$Sample == "s2"], "lower is better")

  # with the metric's weight set to 0 the same value raises nothing
  th <- quality_thresholds_default()
  th$weight[th$metric == "frac_cross_class"] <- 0
  out0 <- overview_red_flags(sc, thresholds = th)
  expect_false(any(out0$Flag == "Cross-class contamination"))
})

test_that("shallow samples are flagged relative to the median, only with >= 2 samples", {
  out <- overview_red_flags(flag_scores(n_unique_pep = c(1000, 1000, 300, 1000)))
  expect_equal(out$Flag, "Low identification depth")
  expect_equal(as.character(out$Sample), "s3")
  expect_match(out$Detail, "30% of the experiment median")

  expect_equal(nrow(overview_red_flags(flag_scores(n = 1, n_unique_pep = 5))), 0L)
  expect_equal(nrow(overview_red_flags(flag_scores(), depth_ratio = 0)), 0L)
})

test_that("a Condition with one BioReplicate gives a Low experiment-level flag", {
  pep <- data.frame(Condition = c("A", "A", "B", "B"),
                    BioReplicate = c("A1", "A2", "B1", "B1"))
  out <- overview_red_flags(flag_scores(), pep_all = pep)
  expect_equal(nrow(out), 1L)
  expect_true(is.na(out$Sample))
  expect_equal(as.character(out$Severity), "Low")
  expect_match(out$Detail, "'B'")
})

test_that("flags are ordered by severity", {
  pep <- data.frame(Condition = "A", BioReplicate = "A1")
  out <- overview_red_flags(flag_scores(composite_score = c(55, 90, 20, 90)), pep_all = pep)
  expect_equal(as.character(out$Severity), c("High", "Medium", "Low"))
})

test_that("qc_samples_from_annotation reads the flag column and degrades to empty", {
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  utils::write.csv(data.frame(Condition = c("A", "A", "B"), BioReplicate = c("A1", "A2", "B1"),
                              TechReplicate = 1, Sample = c("a1", "a2", "b1"),
                              Sample_folder = c("a1", "a2", "b1"), Sample_ID = c("x", "y", "z"),
                              QC = c("QC", "", "TRUE")),
                   f, row.names = FALSE)
  expect_setequal(qc_samples_from_annotation(f, "QC"), c("a1", "b1"))
  expect_equal(qc_samples_from_annotation(f, ""), character(0))
  expect_equal(qc_samples_from_annotation(f, "NoSuchColumn"), character(0))
  expect_equal(qc_samples_from_annotation(tempfile(), "QC"), character(0))
})
