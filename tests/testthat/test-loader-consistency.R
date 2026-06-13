# Cross-loader guarantees: the three loader families must converge on the same
# core pep_all schema and the same zero-Area / run-name semantics. These tests
# guard against silent divergence between FragPipe, DIA-NN, and PEAKS.

test_that("compute_log2area maps zero to the chosen sentinel and otherwise log2()", {
  expect_equal(compute_log2area(c(0, 2, 8)), c(NA, 1, 3))
  expect_equal(compute_log2area(c(0, 2, 8), zero_to = 1), c(1, 1, 3))
  # default sentinel is a real NA, not a fabricated finite value
  expect_true(is.na(compute_log2area(0)))
})

test_that("extract_run_name is separator-agnostic (Windows and POSIX paths)", {
  expect_equal(extract_run_name("D:\\data\\run1.d"), "run1")
  expect_equal(extract_run_name("/mnt/data/run1.d"), "run1")
  expect_equal(extract_run_name("C:/data/run2.raw"), "run2")
  # a backslash path and its forward-slash twin must resolve identically
  expect_equal(extract_run_name("a\\b\\run.raw"), extract_run_name("a/b/run.raw"))
  # vectorised
  expect_equal(extract_run_name(c("x\\run1.d", "y/run2.d")), c("run1", "run2"))
})

test_that("validate_pep_all rejects missing core columns, empty frames, and non-numeric Area", {
  good <- data.frame(Peptide = "AAA", Sequence = "AAA", Length = 3L, Area = 10,
                     Log2Area = log2(10), Length_range = factor("others"),
                     Found_By = "x", PeptideID = "p")
  expect_silent(validate_pep_all(good, "x"))

  expect_error(validate_pep_all(good[, setdiff(names(good), "PeptideID")], "x"),
               "missing required column")
  expect_error(validate_pep_all(good[0, ], "x"), "empty table")

  bad_type <- good
  bad_type$Area <- "10"
  expect_error(validate_pep_all(bad_type, "x"), "non-numeric")
})

test_that("all three loaders converge on the core pep_all schema with numeric Area/Log2Area/Length", {
  fp    <- suppressWarnings(parse_fragpipe(make_fp_psm_raw()))
  diann <- suppressWarnings(parse_diann(make_diann_report_raw()))
  peaks <- suppressMessages(suppressWarnings(
    parse_peaks(read_peaks(test_path("fixtures", "peaks_export"), "JY_PEAKS_01",
                           instrument = "tims_tof"))))

  core <- c("Peptide", "Sequence", "Length", "Area", "Log2Area",
            "Length_range", "Found_By", "PeptideID")
  for (out in list(fp, diann, peaks)) {
    expect_true(all(core %in% names(out)))
    expect_true(is.numeric(out$Area))
    expect_true(is.numeric(out$Log2Area))
    expect_true(is.numeric(out$Length))
    expect_s3_class(out$Length_range, "factor")
    expect_type(out$Found_By, "character")
  }
})
