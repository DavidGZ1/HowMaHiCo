# build_pep_all() is the extracted parse-and-cache step shared by the focused
# report templates. The loader internals are covered by test-loaders-*.R; here
# we exercise the dispatch + caching end to end via the DIA-NN branch, writing
# the complete in-memory DIA-NN fixture (make_diann_report_raw(), minus the
# reader-added Sample_fp column) to a temp report.tsv so the full parse runs.

test_that("build_pep_all errors clearly on an unknown software", {
  expect_error(
    build_pep_all("not_a_real_software", folder_data = ".", annotation = make_annot()),
    "Unknown 'software'"
  )
})

test_that("build_pep_all (DIA-NN) returns a valid pep_all and writes a re-loadable cache", {
  # a real report.tsv has no Sample_fp column (read_diann adds it from the folder)
  raw <- dplyr::select(make_diann_report_raw(), -Sample_fp)
  dir <- tempfile("diann_fixture_")
  dir.create(file.path(dir, "run1"), recursive = TRUE)
  readr::write_tsv(raw, file.path(dir, "run1", "report.tsv"))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  # File.Name "D:\\data\\run1.d" -> Source_file "run1"; Sample_fp "run1" from folder
  annot <- tibble::tribble(
    ~Condition, ~BioReplicate, ~TechReplicate, ~Sample, ~Sample_ID, ~Sample_fp, ~Source_file,
    "A",        "A_1",         "1",            "run1",  "run1_ID",  "run1",     "run1"
  ) |>
    dplyr::mutate(dplyr::across(dplyr::where(is.character), ~ factor(.x, levels = unique(.x))))

  rda <- tempfile(fileext = ".rda")
  on.exit(unlink(rda), add = TRUE)

  pep_all <- suppressWarnings(suppressMessages(
    build_pep_all(software = "diann", folder_data = dir, annotation = annot,
                  shortpep_range = c(8, 13), file_rda = rda)
  ))

  # parse_diann() already runs validate_pep_all(); re-assert the core contract
  expect_silent(validate_pep_all(pep_all, "DIA-NN"))
  expect_gt(nrow(pep_all), 0)
  expect_true(all(c("Condition", "Sample", "Peptide", "Log2Area") %in% names(pep_all)))

  # cache written and re-loadable under the object name `pep_all`
  expect_true(file.exists(rda))
  e <- new.env()
  load(rda, envir = e)
  expect_true(exists("pep_all", envir = e))
  expect_equal(nrow(e$pep_all), nrow(pep_all))
})
