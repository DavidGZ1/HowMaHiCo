test_that("write.csv_rawr names the file after the input variable, optionally prefixed", {
  old_wd <- getwd()
  dir <- "write_csv_rawr_test"
  setwd(tempdir())
  on.exit({ unlink(dir, recursive = TRUE); setwd(old_wd) })
  dir.create(dir)

  counts_pep_all_condition <- data.frame(Condition = c("A", "B"), n_Peptides = c(1L, 2L))
  write.csv_rawr(counts_pep_all_condition, folder = dir)
  expect_true(file.exists(file.path(dir, "counts_pep_all_condition.csv")))

  write.csv_rawr(counts_pep_all_condition, folder = dir, prefix = "dda_all")
  expect_true(file.exists(file.path(dir, "dda_all_counts_pep_all_condition.csv")))

  written <- read.csv(file.path(dir, "counts_pep_all_condition.csv"))
  expect_equal(written, counts_pep_all_condition)
})

test_that("ggsave_rawr saves an existing plot and warns (without erroring) when the named plot doesn't exist", {
  old_wd <- getwd()
  dir <- "ggsave_rawr_test"
  setwd(tempdir())
  on.exit({ unlink(dir, recursive = TRUE); setwd(old_wd) })
  dir.create(dir)

  # The plot is an ordinary local: ggsave_rawr resolves the name in its CALLER's
  # frame. It used to search from the package namespace outwards instead, which
  # never reaches a report's knit environment, so PlotsSave = TRUE silently
  # saved nothing at all.
  p_test_plot <- ggplot2::ggplot(data.frame(x = 1:3, y = 1:3), ggplot2::aes(x, y)) +
    ggplot2::geom_point()

  ggsave_rawr(p_test_plot, "test_plot", folder = dir, width = 4, height = 4)
  expect_true(file.exists(file.path(dir, "test_plot.png")))

  expect_warning(ggsave_rawr(p_does_not_exist, "skipped_plot", folder = dir),
                 "skipped_plot.png was not saved")
  expect_false(file.exists(file.path(dir, "skipped_plot.png")))
})

test_that("ggsave_rawr saves from a knit-like environment and from a plot list", {
  dir <- tempfile("ggsave_rawr_env_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))

  # rmarkdown renders in new.env(parent = globalenv()), never in .GlobalEnv
  knit_env <- new.env(parent = globalenv())
  knit_env$out_dir <- dir
  local({
    p_knit <- ggplot2::ggplot(data.frame(x = 1:3, y = 1:3), ggplot2::aes(x, y)) +
      ggplot2::geom_point()
    ggsave_rawr(p_knit, "knit_plot", folder = out_dir, width = 4, height = 4)

    # the export-loop idiom: an indexed element is judged by value, and a NULL
    # entry (a plot function that could not draw) is skipped, not saved
    plots <- list(kept = p_knit, dropped = NULL)
    for (nm in names(plots))
      suppressWarnings(ggsave_rawr(plots[[nm]], file = nm, folder = out_dir,
                                   width = 4, height = 4))
  }, envir = knit_env)

  expect_true(file.exists(file.path(dir, "knit_plot.png")))
  expect_true(file.exists(file.path(dir, "kept.png")))
  expect_false(file.exists(file.path(dir, "dropped.png")))
})

test_that("write_input_params writes a long-format package-version + timestamp + params table", {
  old_wd <- getwd()
  dir <- "write_input_params_test"
  setwd(tempdir())
  on.exit({ unlink(dir, recursive = TRUE); setwd(old_wd) })
  dir.create(dir)

  params <- list(Software = "fragpipe_dda_combined", Subset = "dda_all", PlotsSave = TRUE)
  write_input_params(params, folder = dir)

  out <- read.csv(file.path(dir, "input_params.csv"))
  expect_equal(names(out), c("Parameter", "Value"))
  expect_setequal(out$Parameter, c("package_version", "render_timestamp", names(params)))
  expect_equal(out$Value[out$Parameter == "package_version"], as.character(utils::packageVersion("HowMaHiCo")))
  expect_equal(out$Value[out$Parameter == "Software"], "fragpipe_dda_combined")
})
