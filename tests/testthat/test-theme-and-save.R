test_that("theme_rawr returns an addable ggplot2 theme object", {
  th <- theme_rawr()
  expect_s3_class(th, "theme")

  p <- ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y)) + ggplot2::geom_point() + theme_rawr(base_size = 10)
  expect_s3_class(p, "ggplot")
})

test_that("ggprint_rawr prints an existing plot and warns (without erroring) when the named plot doesn't exist", {
  # An ordinary local: the name is resolved in the CALLER's frame. It used to be
  # looked up from the package namespace outwards, which never reaches a
  # report's knit environment -- so ggprint_rawr silently dropped every plot a
  # report asked it to display.
  p_test_print_plot <- ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y)) +
    ggplot2::geom_point()

  expect_s3_class(ggprint_rawr(p_test_print_plot), "ggplot")
  expect_warning(ggprint_rawr(p_test_print_plot_missing), "p_test_print_plot_missing was not generated")
})

test_that("ggprint_rawr returns the plot from a knit-like environment and from a list", {
  knit_env <- new.env(parent = globalenv())
  res <- local({
    p_knit <- ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y)) +
      ggplot2::geom_point()
    plots <- list(kept = p_knit, dropped = NULL)
    list(bare    = ggprint_rawr(p_knit),
         indexed = ggprint_rawr(plots[["kept"]]),
         dropped = suppressWarnings(ggprint_rawr(plots[["dropped"]])))
  }, envir = knit_env)

  expect_s3_class(res$bare, "ggplot")
  expect_s3_class(res$indexed, "ggplot")
  expect_null(res$dropped)
})
