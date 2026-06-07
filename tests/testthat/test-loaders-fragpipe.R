test_that("fp_read_psm tags rows with Sample_fp and relocates it first", {
  out <- fp_read_psm(test_path("fixtures", "fragpipe_dda", "JY_1", "psm.tsv"), "JY_1")

  expect_s3_class(out, "data.frame")
  expect_equal(names(out)[1], "Sample_fp")
  expect_equal(unique(out$Sample_fp), "JY_1")
  expect_equal(nrow(out), 2)
})

test_that("fp_read_psm testmode truncates to ~100 rows and warns", {
  expect_warning(
    out <- fp_read_psm(test_path("fixtures", "fragpipe_dda", "JY_1", "psm.tsv"), "JY_1", testmode = TRUE),
    "Test mode ON"
  )
  expect_equal(nrow(out), 2)
})

test_that("fp_read_psm_batch discovers every psm.tsv and derives Sample_fp from the parent folder", {
  out <- fp_read_psm_batch(test_path("fixtures", "fragpipe_dda"))

  # Sample_fp is captured by regex from everything after the *first* path
  # separator in `folder` through the immediate parent dir (matches CLAUDE.md's
  # documented Sample_fp convention, e.g. "fragpipe_dda_combined/JY") -- so only
  # the basename (the immediate parent folder name) is stable across test setups
  expect_setequal(basename(unique(out$Sample_fp)), c("JY_1", "JY_2"))
  expect_equal(nrow(out), 5)
  expect_true(all(c("Spectrum", "Peptide", "Charge") %in% names(out)))
})

test_that("fp_parse_pep_all reshapes raw PSM rows into pep_all schema", {
  raw <- make_fp_psm_raw()
  out <- suppressWarnings(fp_parse_pep_all(raw, shortpep_range = c(8, 13)))

  expect_equal(nrow(out), 4)
  expect_true(all(c("Sample_fp", "Accession", "Peptide", "Sequence", "Length", "Score",
                    "Area", "Log2Area", "Length_range", "PTM", "Charge", "Nter", "Cter",
                    "RT", "invk0", "Mass", "ppm", "m_z", "Source_file", "Source_File_ID",
                    "Precursor_Id", "Found_By", "PeptideID") %in% names(out)))

  expect_equal(out$Found_By, rep("FragPipe", 4))
  expect_equal(as.character(out$Length_range),
               c("8 to 13 AAs", "8 to 13 AAs", "8 to 13 AAs", "others"))
  expect_equal(as.character(out$Charge), rep("+ 2", 4))

  # Modified_Peptide falls back to Peptide when not modified, and is used as the pep_all `Peptide`
  expect_equal(out$Peptide[1], "AAAVAAAAL")
  expect_equal(out$Peptide[2], "AAAVAAAAL(15.9949)")
  expect_equal(out$Sequence[2], "AAAVAAAAL")

  # Source_file is derived from Spectrum by stripping the scan-number suffix
  expect_equal(out$Source_file, rep("run1", 4))
})

test_that("fp_parse_pep_all maps zero-intensity rows to Log2Area = 1 and warns when all-zero", {
  raw <- make_fp_psm_raw()
  out <- suppressWarnings(fp_parse_pep_all(raw))
  zero_row <- out[out$Area == 0, ]

  expect_equal(nrow(zero_row), 1)
  expect_equal(zero_row$Log2Area, 1)

  all_zero <- raw
  all_zero$Intensity <- 0
  expect_warning(fp_parse_pep_all(all_zero), "All Intensity \\(Area\\) values were 0")
})

test_that("fp_annotate joins parsed FragPipe results to the annotation table by Sample_fp", {
  parsed <- suppressWarnings(fp_parse_pep_all(make_fp_psm_raw(samplename = "JY_1")))
  annot <- make_annot()

  out <- suppressWarnings(suppressMessages(fp_annotate(parsed, annot, mode = "individual_files")))

  expect_equal(nrow(out), 4)
  expect_true(all(c("Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_ID") %in% names(out)))
  expect_equal(unique(as.character(out$Sample)), "JY_1")
})

test_that("fp_annotate requires the minimal annotation columns", {
  parsed <- suppressWarnings(fp_parse_pep_all(make_fp_psm_raw()))
  bad_annot <- make_annot()[, setdiff(names(make_annot()), "Condition")]

  expect_error(fp_annotate(parsed, bad_annot), "missing from the annotation table")
})
