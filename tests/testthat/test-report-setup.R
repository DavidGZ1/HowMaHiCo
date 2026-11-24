# report_params() / report_setup() (v0.28.0): the helpers that
# let a focused report be run step by step outside a knit.

sim_dir   <- system.file("extdata", "sim_fragpipe_dda", package = "HowMaHiCo")
sim_annot <- system.file("extdata", "sim_fragpipe_dda_annotation.csv", package = "HowMaHiCo")

test_that("report_params() returns the template defaults with overrides applied", {
  p <- report_params("03_lcms_qc")
  expect_type(p, "list")
  expect_true(all(c("SampleSet", "Subset", "FolderData", "MHCclass",
                    "PepAllSource") %in% names(p)))
  expect_equal(p$MHCclass, "MHC1")
  expect_equal(p$PepAllSource, "cached")

  p2 <- report_params("03_lcms_qc", MHCclass = "MHC2",
                      .params = list(Subset = "dda_all", MHCclass = "MHC1"))
  expect_equal(p2$MHCclass, "MHC2")          # ... wins over .params
  expect_equal(p2$Subset, "dda_all")
  expect_setequal(names(p2), names(p))       # nothing added or dropped
})

test_that("report_params() rejects undeclared params, naming the valid ones", {
  expect_error(report_params("03_lcms_qc", Titel = "x"),
               "does not declare the parameter\\(s\\) 'Titel'.*Valid parameters")
  # 05_quant_stats params are not 03_lcms_qc params
  expect_error(report_params("03_lcms_qc", StatMethod = "ttest"), "StatMethod")
  expect_equal(report_params("05_quant_stats", StatMethod = "ttest")$StatMethod,
               "ttest")
})

test_that("report_params() resolves pre-v0.27.0 template names", {
  expect_warning(p <- report_params("07_pepchem"), "renamed")
  expect_true("PropertySet" %in% names(p))
})

test_that("run_howmahico_report() fails before rendering on an undeclared param", {
  expect_error(run_howmahico_report("03_lcms_qc", params = list(Title = "x"),
                                    output_file = tempfile(fileext = ".html")),
               "does not declare")
})

test_that("report_setup() assigns the documented objects (PepAllSource = build)", {
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  proj <- tempfile("setupproj_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  p <- report_params("03_lcms_qc",
                     Software = "fragpipe_dda_individual",
                     FolderDocumentation = proj,
                     AnnotationFile = "sim_fragpipe_dda_annotation.csv",
                     FolderData = file.path(proj, "sim_fragpipe_dda"),
                     FolderResults = proj, FolderFigures = proj,
                     PepAllSource = "build", Subset = "sim", MHCclass = "MHC2")
  e <- new.env()
  res <- suppressWarnings(suppressMessages(report_setup(p, envir = e)))

  documented <- c("shortpep_range", "shortpep_palette", "shortpep_colors",
                  "interactive_plots", "subset", "FolderResults", "FolderFigures",
                  "result_prefix", "file_rda", "pep_all", "pep_short", "samples",
                  "conditions", "n_conditions", "bioreplicates", "comp_condition",
                  "phis_nrow", "phis_ncol")
  expect_setequal(names(res), documented)
  for (nm in documented) expect_true(exists(nm, envir = e, inherits = FALSE), info = nm)

  expect_equal(e$shortpep_range, c(12, 25))
  expect_true(all(e$pep_short$Length >= 12 & e$pep_short$Length <= 25))
  expect_setequal(e$conditions, c("CTRL", "TREAT"))
  expect_equal(e$n_conditions, 2L)
  expect_length(e$comp_condition, 1L)
  expect_equal(e$result_prefix, "sim")
  expect_equal(e$FolderResults, file.path(proj, "sim"))
  expect_true(dir.exists(e$FolderResults))
  expect_false(e$interactive_plots)
  # the build branch wrote the cache, so the cached branch can now load it
  expect_true(file.exists(e$file_rda))

  e2 <- new.env()
  p$PepAllSource <- "cached"
  suppressMessages(report_setup(p, envir = e2))
  expect_equal(nrow(e2$pep_all), nrow(e$pep_all))
})

test_that("report_setup() works on a partial params list and names a missing cache", {
  d <- tempfile("nocache_"); dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  expect_error(report_setup(list(FolderData = d, FolderResults = d, FolderFigures = d),
                            envir = new.env()),
               "pep_all cache not found")
  expect_error(report_setup(list(FolderData = d, FolderResults = d, FolderFigures = d,
                                 PepAllSource = "nope"), envir = new.env()),
               "Unknown PepAllSource")
})
