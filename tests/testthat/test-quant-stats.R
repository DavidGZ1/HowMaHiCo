# Tests for the advanced-quantification engine (R/quant-stats.R). Like
# test-quality-score.R these work on small hand-built inputs: the point is the
# maths (aggregation, filtering, normalization, imputation, testing), not the
# search-engine parsing, which the loader tests already cover.

# 2 Conditions x 3 BioReplicates x 2 TechReplicates, one peptide seen at two
# charge states, one peptide exclusive to TREAT, one peptide seen once only.
make_long <- function() {
  units <- paste0("BR", 1:6)
  cond  <- rep(c("CTRL", "TREAT"), each = 3)
  base <- do.call(rbind, lapply(seq_along(units), function(j) {
    data.frame(
      Peptide      = c("PEPA", "PEPB", "PEPEXCL", "PEPONCE"),
      Sample       = paste0(units[j], "_t1"),
      BioReplicate = units[j],
      Condition    = cond[j],
      Area         = c(100, 200, 400, 800),
      stringsAsFactors = FALSE)
  }))
  tech <- base
  tech$Sample <- sub("_t1", "_t2", tech$Sample)
  both <- rbind(base, tech)
  # PEPA is also seen as a second charge state in every sample (same Area)
  charge2 <- both[both$Peptide == "PEPA", ]
  long <- rbind(both, charge2)

  long$Area[long$Peptide == "PEPEXCL" & long$Condition == "CTRL"] <- NA
  long$Area[long$Peptide == "PEPONCE" & !(long$BioReplicate == "BR1")] <- NA

  long$Condition    <- factor(long$Condition, levels = c("CTRL", "TREAT"))
  long$BioReplicate <- factor(long$BioReplicate, levels = units)
  long$Sample       <- factor(long$Sample)
  long
}

test_that("build_quant_matrix sums charge states, averages tech reps and keeps factor order", {
  qm <- build_quant_matrix(make_long())

  expect_equal(colnames(qm$mat), paste0("BR", 1:6))
  expect_setequal(rownames(qm$mat), c("PEPA", "PEPB", "PEPEXCL", "PEPONCE"))
  # PEPA: 100 + 100 summed on the linear scale inside each sample, then averaged
  # over the two technical replicates -> log2(200), not log2(100) or log2(400)
  expect_equal(unname(qm$mat["PEPA", "BR1"]), log2(200))
  expect_equal(unname(qm$mat["PEPB", "BR1"]), log2(200))
  # exclusive peptide is NA in the CTRL columns, quantified in TREAT
  expect_true(all(is.na(qm$mat["PEPEXCL", 1:3])))
  expect_true(all(!is.na(qm$mat["PEPEXCL", 4:6])))

  expect_equal(as.character(qm$coldata$Unit), colnames(qm$mat))
  expect_equal(as.character(qm$coldata$Condition), rep(c("CTRL", "TREAT"), each = 3))
  expect_equal(qm$coldata$n_Samples, rep(2L, 6))
})

test_that("filter_quant keeps features quantified in one group and drops singletons", {
  qm <- build_quant_matrix(make_long())
  out <- filter_quant(qm$mat, qm$coldata, min_per_group = 2)

  expect_true("PEPEXCL" %in% rownames(out))   # 3 units in TREAT
  expect_false("PEPONCE" %in% rownames(out))  # only BR1
  expect_equal(attr(out, "n_dropped"), 1L)
  expect_equal(attr(out, "dropped"), "PEPONCE")
})

test_that("normalize_quant(median) equalizes column medians and preserves NAs", {
  mat <- matrix(c(1, 2, 3, 11, 12, NA), nrow = 3,
                dimnames = list(paste0("f", 1:3), c("A", "B")))
  out <- normalize_quant(mat, "median")

  meds <- apply(out, 2, stats::median, na.rm = TRUE)
  expect_equal(unname(meds[1]), unname(meds[2]))
  expect_true(is.na(out["f3", "B"]))
  expect_equal(dim(out), dim(mat))
  expect_equal(dimnames(out), dimnames(mat))
  expect_identical(normalize_quant(mat, "none"), mat)
})

test_that("impute_quant fills only missing values, reproducibly, at the low end", {
  set.seed(99)
  mat <- matrix(c(rnorm(20, 20, 1), rnorm(20, 20, 1)), nrow = 20,
                dimnames = list(paste0("f", 1:20), c("A", "B")))
  mat[1:5, "A"] <- NA

  none <- impute_quant(mat, "none")
  expect_true(all(is.na(none[1:5, "A"])))
  expect_false(any(attr(none, "imputed")))

  imp1 <- impute_quant(mat, "minprob", seed = 7)
  imp2 <- impute_quant(mat, "minprob", seed = 7)
  expect_equal(imp1, imp2)
  expect_false(any(is.na(imp1)))
  expect_equal(sum(attr(imp1, "imputed")), 5L)
  # untouched cells are unchanged, imputed ones sit at the low end (by
  # construction mean - 1.8 sd with width 0.3 sd, so below the observed mean)
  expect_equal(unname(imp1[6:20, "A"]), unname(mat[6:20, "A"]))
  expect_lt(max(imp1[1:5, "A"]), mean(mat[6:20, "A"], na.rm = TRUE))

  det <- impute_quant(mat, "mindet")
  expect_equal(length(unique(det[1:5, "A"])), 1L)
})

test_that("test_differential recovers a spiked fold change (ttest and limma agree)", {
  set.seed(11)
  n <- 40
  mat <- matrix(rnorm(n * 6, 20, 0.2), nrow = n,
                dimnames = list(paste0("f", seq_len(n)), paste0("U", 1:6)))
  mat[1:5, 4:6] <- mat[1:5, 4:6] + 3     # spiked up in TREAT
  coldata <- data.frame(Unit = factor(colnames(mat), levels = colnames(mat)),
                        Condition = factor(rep(c("CTRL", "TREAT"), each = 3),
                                           levels = c("CTRL", "TREAT")))

  res_t <- test_differential(mat, coldata, method = "ttest")
  expect_equal(unique(res_t$Contrast), "TREAT_vs_CTRL")
  expect_equal(nrow(res_t), n)
  expect_true(all(res_t$logFC[1:5] > 2))
  expect_true(all(res_t$adj.P.Val[1:5] < 0.05))
  expect_equal(res_t$n_obs_ref[1], 3L)

  skip_if_not_installed("limma")
  res_l <- test_differential(mat, coldata, method = "limma")
  expect_equal(nrow(res_l), n)
  expect_equal(res_l$logFC, res_t$logFC, tolerance = 1e-8)   # same estimate
  expect_true(all(res_l$adj.P.Val[1:5] < 0.05))
  expect_false(is.null(attr(res_l, "fit")))
  # moderation only changes the variance, so the two rankings must agree closely
  expect_gt(stats::cor(rank(res_l$P.Value), rank(res_t$P.Value), use = "complete.obs"), 0.9)
})

test_that("test_detection flags condition-exclusive features", {
  qm <- build_quant_matrix(make_long())
  det <- test_detection(qm$mat, qm$coldata)

  excl <- det[det$Feature == "PEPEXCL", ]
  expect_equal(excl$Exclusive_in, "TREAT")
  expect_equal(c(excl$n_det_ref, excl$n_det_test), c(0L, 3L))
  expect_lt(excl$P.Value_det, 0.2)

  even <- det[det$Feature == "PEPA", ]
  expect_true(is.na(even$Exclusive_in))
  expect_equal(even$P.Value_det, 1)
})

test_that("combine_quant_results flags exclusives by detection count, not by FDR", {
  qm <- build_quant_matrix(make_long())
  mat <- filter_quant(qm$mat, qm$coldata)
  diff_res <- test_differential(mat, qm$coldata, method = "ttest")
  det_res  <- test_detection(mat, qm$coldata)
  comb <- combine_quant_results(diff_res, det_res, min_detect = 2)

  # a 3-vs-3 Fisher test cannot go below p = 0.1, so an FDR rule would hide this
  expect_gt(comb$adj.P.Val_det[comb$Feature == "PEPEXCL"], 0.05)
  expect_equal(as.character(comb$Status[comb$Feature == "PEPEXCL"]), "exclusive_up")

  summ <- summarise_significant(comb)
  expect_equal(summ$exclusive_up, 1L)
  expect_equal(nrow(summ), 1L)
})

test_that("permanova_condition separates two clearly distinct groups", {
  set.seed(5)
  # 4 units per group: with 3 vs 3 only C(6,3)/2 = 10 distinct label assignments
  # exist, so the smallest attainable permutation p-value is ~0.1
  mat <- matrix(rnorm(50 * 8, 20, 0.2), nrow = 50,
                dimnames = list(paste0("f", 1:50), paste0("U", 1:8)))
  mat[, 5:8] <- mat[, 5:8] + 5
  coldata <- data.frame(Unit = factor(colnames(mat), levels = colnames(mat)),
                        Condition = factor(rep(c("A", "B"), each = 4), levels = c("A", "B")))

  out <- permanova_condition(mat, coldata, n_perm = 199)
  expect_true(out$p_value >= 0 && out$p_value <= 1)
  expect_lt(out$p_value, 0.05)
  expect_gt(out$F, 1)
  expect_equal(out$n_features, 50L)

  one_group <- coldata; one_group$Condition <- factor("A")
  expect_warning(res <- permanova_condition(mat, one_group, n_perm = 9))
  expect_null(res)
})

test_that("the limma guard names an install route and the fallback", {
  msg <- tryCatch(HowMaHiCo:::.require_limma(), error = function(e) conditionMessage(e))
  if (requireNamespace("limma", quietly = TRUE)) {
    expect_true(isTRUE(msg))
  } else {
    expect_match(msg, "BiocManager")
    expect_match(msg, "ttest")
  }
})

test_that("plot_quant_heatmap draws the clusters it computes", {
  set.seed(7)
  m <- matrix(rnorm(60 * 6), 60,
              dimnames = list(paste0("f", 1:60), paste0("u", 1:6)))
  m[1:20, 1:3] <- m[1:20, 1:3] + 3
  m[5, 2] <- NA
  cd <- data.frame(Unit = colnames(m),
                   Condition = factor(rep(c("A", "B"), each = 3)))

  p <- plot_quant_heatmap(m, cd, cluster = TRUE, top_n = 40, n_clusters = 3)
  expect_s3_class(p, "ggarrange")
  cl <- attr(p, "clusters")
  expect_equal(nrow(cl), 40)
  expect_equal(levels(cl$Cluster), c("C1", "C2", "C3"))
  # C1 is the top block: clusters appear in display order, each contiguous
  expect_equal(rle(as.character(cl$Cluster))$values, c("C1", "C2", "C3"))

  # the annotation-order view stays a single (plotly-convertible) ggplot
  q <- plot_quant_heatmap(m, cd, cluster = FALSE, top_n = 40)
  expect_true(HowMaHiCo:::.is_ggplotly_safe(q))
  expect_null(attr(q, "clusters"))

  # too small to cluster: falls back to the single plot
  expect_true(HowMaHiCo:::.is_ggplotly_safe(
    plot_quant_heatmap(m[1:2, ], cd, cluster = TRUE)))
})

test_that(".dendro_segments places every leaf and tops out at the root", {
  hc <- stats::hclust(stats::dist(c(1, 2, 10, 11)))
  s <- HowMaHiCo:::.dendro_segments(hc)
  expect_equal(nrow(s), 3 * 3)
  expect_setequal(s$x[s$y == 0], 1:4)
  expect_equal(max(s$yend), max(hc$height))
})
