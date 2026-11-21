# compare_runs() / summarise_runs() / plot_run_trend(): stacking the per-sample
# score tables that several 01_mhc_overview renders write (or, before v0.27.0, 05_quality_score).

# a minimal score table in the shape score_sample_quality() returns
fake_scores <- function(samples, composite, extra = list()) {
  df <- data.frame(Sample = samples,
                   frac_in_window = seq(0.9, 0.7, length.out = length(samples)),
                   n_unique_pep_in_window = seq_along(samples) * 100,
                   composite_score = composite,
                   category = ifelse(composite >= 70, "Pass",
                                     ifelse(composite >= 40, "Warning", "Fail")),
                   is_QC = c(TRUE, rep(FALSE, length(samples) - 1)),
                   stringsAsFactors = FALSE)
  for (nm in names(extra)) df[[nm]] <- extra[[nm]]
  df
}

# write a score csv (+ optional companion params) the way 01_mhc_overview does;
# report = "05_quality_score" writes the pre-v0.27.0 params name instead
write_run <- function(dir, subset, scores, params = NULL, report = "01_mhc_overview") {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  prefix <- if (nzchar(subset)) paste0(subset, "_") else ""
  utils::write.csv(scores, file.path(dir, paste0(prefix, "scores.csv")), row.names = FALSE)
  if (!is.null(params)) {
    utils::write.csv(data.frame(Parameter = names(params), Value = unlist(params)),
                     file.path(dir, paste0(prefix, report, "_input_params.csv")),
                     row.names = FALSE)
  }
  invisible(dir)
}

test_that("results written by the old 05_quality_score report still stack", {
  root <- tempfile("runs_legacy_"); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  meta <- list(SampleSet = "OLD", Subset = "jy", MHCclass = "MHC2",
               ThresholdMode = "default")
  d_old <- write_run(file.path(root, "old"), "jy", fake_scores(c("s1", "s2"), c(80, 60)),
                     meta, report = "05_quality_score")
  d_new <- write_run(file.path(root, "new"), "jy", fake_scores(c("s1", "s2"), c(70, 50)),
                     utils::modifyList(meta, list(SampleSet = "NEW")))

  out <- compare_runs(c(d_old, d_new))
  expect_equal(levels(out$Run), c("OLD | jy", "NEW | jy"))
  expect_equal(unique(out$MHCclass), "MHC2")
})

test_that("data frames stack with label precedence names > runN and a column union", {
  a <- fake_scores(c("s1", "s2"), c(80, 60))
  b <- fake_scores(c("s1", "s3", "s4"), c(30, 90, 75), extra = list(frac_nested_core = 0.4))
  out <- compare_runs(list(first = a, b))

  expect_equal(levels(out$Run), c("first", "run2"))
  expect_equal(nrow(out), 5L)
  expect_true("frac_nested_core" %in% names(out))
  expect_true(all(is.na(out$frac_nested_core[out$Run == "first"])))
  # Sample is character, because the same sample name can recur across runs
  expect_type(out$Sample, "character")

  out2 <- compare_runs(list(a, b), labels = c("A", "B"))
  expect_equal(levels(out2$Run), c("A", "B"))
  expect_error(compare_runs(list(a, b), labels = "only one"), "2 run")
})

test_that("csv input picks up the companion input_params and labels from them", {
  root <- tempfile("runs_"); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  d1 <- write_run(file.path(root, "dda_jy"), "dda_jy", fake_scores(c("s1", "s2"), c(80, 60)),
                  list(SampleSet = "EXP1", Subset = "dda_jy", MHCclass = "MHC1",
                       ThresholdMode = "default", render_timestamp = "2026-05-02 10:00:00",
                       package_version = "0.24.0"))
  d2 <- write_run(file.path(root, "plasma"), "", fake_scores(c("p1", "p2"), c(50, 20)))

  out <- compare_runs(c(d1, d2))
  expect_equal(levels(out$Run), c("EXP1 | dda_jy", "plasma"))
  expect_equal(unique(out$MHCclass[out$Run == "EXP1 | dda_jy"]), "MHC1")
  expect_true(all(is.na(out$MHCclass[out$Run == "plasma"])))
  expect_true(all(file.exists(out$source_file)))

  # a direct file path works too, and an explicit name wins over the params
  out_f <- compare_runs(c(mine = file.path(d1, "dda_jy_scores.csv")))
  expect_equal(levels(out_f$Run), "mine")
})

test_that("timestamp ordering sorts runs and puts undated ones last", {
  root <- tempfile("runs_"); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  mk <- function(name, ts) write_run(file.path(root, name), name,
                                     fake_scores(c("a", "b"), c(70, 70)),
                                     if (!is.na(ts)) list(SampleSet = name, render_timestamp = ts))
  d_late  <- mk("late",  "2026-06-01 09:00:00")
  d_early <- mk("early", "2026-01-01 09:00:00")
  d_none  <- mk("none",  NA)

  expect_warning(out <- compare_runs(c(d_late, d_none, d_early), order = "timestamp"),
                 "no render_timestamp|No render_timestamp")
  expect_equal(levels(out$Run), c("early", "late", "none"))
  # input order is the default
  out_in <- suppressWarnings(compare_runs(c(d_late, d_none, d_early)))
  expect_equal(levels(out_in$Run), c("late", "none", "early"))
})

test_that("mismatched MHCclass or ThresholdMode warns; missing inputs error clearly", {
  root <- tempfile("runs_"); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  d1 <- write_run(file.path(root, "c1"), "c1", fake_scores("s1", 80),
                  list(SampleSet = "X", MHCclass = "MHC1", ThresholdMode = "default"))
  d2 <- write_run(file.path(root, "c2"), "c2", fake_scores("s1", 80),
                  list(SampleSet = "Y", MHCclass = "MHC2", ThresholdMode = "default"))
  expect_warning(compare_runs(c(d1, d2)), "MHCclass")

  empty <- file.path(root, "empty"); dir.create(empty)
  expect_error(compare_runs(empty), "No '\\*scores.csv'")
  expect_error(compare_runs(file.path(root, "nope")), "does not exist")
  expect_error(compare_runs(list(data.frame(x = 1))), "no 'Sample' column")
})

test_that("duplicate labels are made unique with a warning", {
  a <- fake_scores("s1", 80)
  expect_warning(out <- compare_runs(list(x = a, x = a)), "Duplicate run labels")
  expect_equal(nlevels(out$Run), 2L)
})

test_that("summarise_runs gives per-run medians and category counts", {
  out <- compare_runs(list(A = fake_scores(c("s1", "s2", "s3"), c(80, 60, 20)),
                           B = fake_scores(c("s1", "s2"), c(90, 75))))
  s <- summarise_runs(out, metrics = "composite_score")
  expect_equal(s$median, c(60, 82.5))
  expect_equal(s$n_Pass, c(1L, 2L))
  expect_equal(s$n_Fail, c(1L, 0L))
  expect_equal(s$label, c("Composite score", "Composite score"))

  # the default picks every known metric present in the table
  s_all <- summarise_runs(out)
  expect_setequal(unique(s_all$metric),
                  c("composite_score", "frac_in_window", "n_unique_pep_in_window"))
  expect_error(summarise_runs(out, metrics = "bogus"), "bogus")
})

test_that("plot_run_trend builds both plot types and validates its inputs", {
  out <- compare_runs(list(A = fake_scores(c("s1", "s2"), c(80, 60), list(Condition = c("c", "t"))),
                           B = fake_scores(c("s1", "s2"), c(90, 75), list(Condition = c("c", "t")))))
  expect_s3_class(plot_run_trend(out), "ggplot")
  expect_s3_class(plot_run_trend(out, type = "line", color_by = "Condition"), "ggplot")
  expect_no_error(ggplot2::ggplot_build(plot_run_trend(out, type = "line")))
  expect_error(plot_run_trend(out, metrics = "bogus"), "bogus")
  expect_error(plot_run_trend(out, color_by = "bogus"), "bogus")
})

test_that("real score tables from the FragPipe and PEAKS fixtures stack end to end", {
  fp_dir   <- system.file("extdata", "sim_fragpipe_dda", package = "HowMaHiCo")
  fp_annot <- system.file("extdata", "sim_fragpipe_dda_annotation.csv", package = "HowMaHiCo")
  pk_dir   <- system.file("extdata", "sim_peaks_xpro", package = "HowMaHiCo")
  pk_annot <- system.file("extdata", "sim_peaks_xpro_annotation.csv", package = "HowMaHiCo")
  skip_if(any(c(fp_dir, fp_annot, pk_dir, pk_annot) == ""), "simulated extdata not installed")

  fp <- suppressWarnings(suppressMessages(
    build_pep_all("fragpipe_dda_individual", folder_data = fp_dir,
                  annotation = read_annot(fp_annot), shortpep_range = c(8, 13))))
  pk <- suppressWarnings(suppressMessages(
    build_pep_all("peaks_xpro", folder_data = pk_dir, annotation = read_annot(pk_annot),
                  shortpep_range = c(8, 13), instrument = "tims_tof")))
  sc_fp <- score_sample_quality(fp, c(8, 13), "MHC1")
  sc_pk <- score_sample_quality(pk, c(8, 13), "MHC1")

  root <- tempfile("runs_"); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  params <- function(sub) list(SampleSet = "sim", Subset = sub, MHCclass = "MHC1",
                               ThresholdMode = "default")
  d_fp <- write_run(file.path(root, "fp"), "fp", sc_fp, params("fp"))
  d_pk <- write_run(file.path(root, "pk"), "pk", sc_pk, params("pk"))

  out <- compare_runs(c(d_fp, d_pk))
  expect_equal(levels(out$Run), c("sim | fp", "sim | pk"))
  expect_equal(nrow(out), nrow(sc_fp) + nrow(sc_pk))
  expect_equal(out$composite_score[out$Run == "sim | fp"],
               sc_fp$composite_score)
  expect_s3_class(plot_run_trend(out), "ggplot")
  expect_equal(nrow(summarise_runs(out, "composite_score")), 2L)
})
