# Tests for get_pipeline_script() (v0.17.0), the sibling of
# get_report_template()/get_dictionary_template() that hands the user a runnable,
# commented walkthrough of the whole pipeline.
#
# The script is shipped source, not package code, so nothing in R CMD check
# parses it. It is checked here instead: a syntax error in a shipped Rmd/script
# is exactly the failure mode that left 05_quality_score unrenderable for three
# releases, and it is only ever caught at the moment someone runs the file.

test_that("get_pipeline_script copies the script and returns the path invisibly", {
  dir <- tempfile("pipeline_script_"); dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))
  dest <- file.path(dir, "howmahico_pipeline.R")

  expect_message(out <- get_pipeline_script(dest), "Pipeline script written to")

  expect_true(file.exists(dest))
  expect_equal(out, dest)
  expect_gt(file.size(dest), 0)

  # identical to the shipped copy, not a truncated or re-encoded one
  src <- system.file("scripts", "howmahico_pipeline.R", package = "HowMaHiCo")
  expect_equal(readLines(dest, warn = FALSE), readLines(src, warn = FALSE))
})

test_that("get_pipeline_script refuses to clobber an existing file", {
  dir <- tempfile("pipeline_script_"); dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))
  dest <- file.path(dir, "howmahico_pipeline.R")
  writeLines("# my edited pipeline", dest)

  expect_error(get_pipeline_script(dest), "already exists")
  # the user's edits survive the refusal
  expect_equal(readLines(dest, warn = FALSE), "# my edited pipeline")

  suppressMessages(get_pipeline_script(dest, overwrite = TRUE))
  expect_gt(length(readLines(dest, warn = FALSE)), 1)
})

test_that("the shipped pipeline script is syntactically valid R", {
  src <- system.file("scripts", "howmahico_pipeline.R", package = "HowMaHiCo")
  expect_true(nzchar(src) && file.exists(src))

  expect_no_error(parse(src))
})

test_that("the shipped pipeline script stays in step with the package API", {
  src <- system.file("scripts", "howmahico_pipeline.R", package = "HowMaHiCo")
  skip_if(src == "", "pipeline script not installed")
  code <- paste(readLines(src, warn = FALSE), collapse = "\n")

  # It must render through the package entry point rather than telling the
  # reader to open a template and knit it -- the point of the script.
  expect_true(grepl("run_howmahico_report(", code, fixed = TRUE))

  # Every template it names must actually be offered by run_howmahico_report(),
  # so a renamed template cannot leave the script pointing at a dead name (the
  # legacy example script still calls the pre-v0.7.0 "01_mhc_report").
  offered <- eval(formals(run_howmahico_report)$template)
  named <- unique(unlist(regmatches(
    code, gregexpr('"[0-9]{2}_[a-z_]+"', code))))
  named <- gsub('"', "", named)
  expect_true(length(named) > 0)
  expect_equal(setdiff(named, offered), character(0))

  # Demo mode is what makes the script runnable on a fresh install, and it
  # depends on the simulated dataset staying where it is.
  expect_true(grepl("RUN_DEMO", code, fixed = TRUE))
  expect_true(grepl("sim_fragpipe_dda", code, fixed = TRUE))
  expect_true(nzchar(system.file("extdata", "sim_fragpipe_dda",
                                 package = "HowMaHiCo")))
})
