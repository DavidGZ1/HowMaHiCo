test_that("theme_rawr returns an addable ggplot2 theme object", {
  th <- theme_rawr()
  expect_s3_class(th, "theme")

  p <- ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y)) + ggplot2::geom_point() + theme_rawr(base_size = 10)
  expect_s3_class(p, "ggplot")
})

test_that("ggprint_rawr prints an existing plot and warns (without erroring) when the named plot doesn't exist", {
  # ggprint_rawr's exists(deparse(substitute(input))) check walks lexical scope
  # from the package namespace -- see test-io-export.R's ggsave_rawr test for why
  # the plot must be bound in .GlobalEnv to be visible
  assign("p_test_print_plot", ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y)) + ggplot2::geom_point(),
         envir = globalenv())
  on.exit(rm("p_test_print_plot", envir = globalenv()))

  expect_s3_class(ggprint_rawr(p_test_print_plot), "ggplot")
  expect_warning(ggprint_rawr(p_test_print_plot_missing), "p_test_print_plot_missing was not generated")
})
