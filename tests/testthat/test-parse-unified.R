# Tests for the dictionary-driven unified parser (R/parse-unified.R,
# R/loaders-custom.R) and the build_pep_all() "custom" branch. Uses the shipped
# simulated FragPipe dataset + the reference fragpipe.yaml dictionary, asserting
# the engine reproduces the built-in FragPipe loader on the directly-mappable
# columns (a strong round-trip check against known-good output).

sim_dir   <- system.file("extdata", "sim_fragpipe_dda", package = "HowMaHiCo")
sim_annot <- system.file("extdata", "sim_fragpipe_dda_annotation.csv", package = "HowMaHiCo")
fp_dict   <- system.file("extdata", "dictionaries", "fragpipe.yaml", package = "HowMaHiCo")

test_that("read_dictionary fills defaults and validates required keys", {
  skip_if(fp_dict == "", "fragpipe.yaml dictionary not installed")
  dict <- read_dictionary(fp_dict)
  expect_equal(dict$found_by, "FragPipe")
  expect_equal(dict$mode, "individual_files")
  expect_equal(dict$read$file, "psm.tsv")
  expect_identical(dict$read$delim, "\t")
  expect_true(dict$derive$format_charge)
  expect_equal(dict$derive$peptide_id, c("Accession", "m_z", "Charge"))
})

test_that("read_dictionary errors on missing columns or missing core targets", {
  no_cols <- tempfile(fileext = ".yaml")
  writeLines("found_by: X", no_cols)
  expect_error(read_dictionary(no_cols), "columns")

  no_core <- tempfile(fileext = ".yaml")
  writeLines(c("found_by: X", "columns:", "  Area: intensity"), no_core)
  expect_error(read_dictionary(no_core), "missing required target")

  expect_error(read_dictionary(tempfile(fileext = ".yaml")), "not found")
})

test_that("parse_unified reproduces the FragPipe loader on directly-mappable columns", {
  skip_if(sim_dir == "" || sim_annot == "" || fp_dict == "",
          "sim_fragpipe_dda / fragpipe.yaml extdata not installed")
  annot <- read_annot(sim_annot)

  uni <- read_custom_batch(folder = sim_dir, annotation = annot,
                           file = "psm.tsv", delim = "\t") |>
    parse_unified(fp_dict, shortpep_range = c(8, 13))
  expect_silent(validate_pep_all(uni, "custom"))

  fp <- suppressWarnings(
    read_fragpipe_batch(folder = sim_dir, annotation = annot) |>
      parse_fragpipe(shortpep_range = c(8, 13)))

  expect_equal(nrow(uni), nrow(fp))

  cols <- c("Sequence", "Length", "Length_range", "Score", "Area", "Log2Area",
            "Charge", "Nter", "Cter", "m_z", "Mass", "PeptideID", "Found_By")
  ord <- function(d) d[order(d$Sequence, d$m_z, d$PeptideID), cols, drop = FALSE]
  expect_equal(as.data.frame(ord(uni)), as.data.frame(ord(fp)),
               ignore_attr = TRUE)
})

test_that("build_pep_all('custom') yields a valid annotated pep_all", {
  skip_if(sim_dir == "" || sim_annot == "" || fp_dict == "",
          "sim_fragpipe_dda / fragpipe.yaml extdata not installed")
  annot <- read_annot(sim_annot)
  pep_all <- suppressWarnings(suppressMessages(
    build_pep_all("custom", folder_data = sim_dir, annotation = annot,
                  shortpep_range = c(8, 13), dictionary = fp_dict)))

  expect_silent(validate_pep_all(pep_all, "custom"))
  expect_setequal(levels(pep_all$Condition), c("CTRL", "TREAT"))
  expect_equal(dplyr::n_distinct(pep_all$Sample), 6L)
  expect_true(all(c("Condition", "Sample_ID", "PeptideID") %in% names(pep_all)))
})

test_that("build_pep_all('custom') requires a dictionary", {
  expect_error(
    build_pep_all("custom", folder_data = sim_dir, annotation = data.frame()),
    "requires a 'dictionary'")
})
