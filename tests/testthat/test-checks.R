test_that("check_file_exists errors when overwrite = FALSE, warns when overwrite = TRUE, stays silent otherwise", {
  old_wd <- getwd()
  f <- "check_file_exists_test.csv"
  setwd(tempdir())
  on.exit({ unlink(f); setwd(old_wd) })
  writeLines("a,b", f)

  expect_error(check_file_exists(f, overwrite = FALSE), "already exists")
  expect_warning(check_file_exists(f, overwrite = TRUE), "already exists")
  expect_silent(check_file_exists("check_file_exists_does_not_exist.csv", overwrite = FALSE))
})

test_that("check_output_exists errors listing every conflicting result file, stays silent when none exist", {
  old_wd <- getwd()
  dir <- "check_output_exists_test"
  setwd(tempdir())
  on.exit({ unlink(dir, recursive = TRUE); setwd(old_wd) })
  dir.create(dir)
  writeLines("a,b", file.path(dir, "pep_all.csv"))
  writeLines("a,b", file.path(dir, "upset_table_pep.csv"))

  expect_error(suppressWarnings(check_output_exists(dir, overwrite = FALSE)), "conflicting result files")
  expect_silent(check_output_exists(file.path(dir, "empty_subdir"), overwrite = FALSE))
})
