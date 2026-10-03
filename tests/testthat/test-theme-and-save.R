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

# ggprint_rawr(interactive = TRUE) is what the InteractivePlots param flips
# (v0.21.0). It must keep the not-generated guard, and must hand back the static
# plot rather than erroring for the object classes ggplotly() cannot convert.

test_that("ggprint_rawr(interactive = TRUE) converts a plain ggplot to a widget", {
  skip_if_not_installed("plotly")
  p_simple <- ggplot2::ggplot(data.frame(x = 1:3, y = 1:3), ggplot2::aes(x, y)) +
    ggplot2::geom_point()

  expect_s3_class(ggprint_rawr(p_simple, interactive = TRUE), "plotly")
  expect_s3_class(ggprint_rawr(p_simple, interactive = TRUE), "htmlwidget")
  # the default is unchanged, so every existing call site still prints a ggplot
  expect_s3_class(ggprint_rawr(p_simple), "ggplot")
  expect_false(inherits(ggprint_rawr(p_simple), "plotly"))
})

test_that("interactive = TRUE keeps the not-generated guard", {
  expect_warning(res <- ggprint_rawr(p_never_built_at_all, interactive = TRUE),
                 "p_never_built_at_all was not generated")
  expect_null(res)
})

test_that("unconvertible plot objects are returned unchanged instead of erroring", {
  skip_if_not_installed("plotly")
  # ggpubr composites (plot_peplength_dens, plot_pepmass, ...) are the real case:
  # ggplotly() cannot take them apart
  p1 <- ggplot2::ggplot(data.frame(x = 1:3, y = 1:3), ggplot2::aes(x, y)) +
    ggplot2::geom_point()
  p_composite <- ggpubr::ggarrange(p1, p1, nrow = 2)
  expect_false(HowMaHiCo:::.is_ggplotly_safe(p_composite))
  expect_identical(ggprint_rawr(p_composite, interactive = TRUE), p_composite)

  # a non-plot, and something that is already a widget
  expect_false(HowMaHiCo:::.is_ggplotly_safe(data.frame(x = 1)))
  already <- plotly::ggplotly(p1)
  expect_false(HowMaHiCo:::.is_ggplotly_safe(already))
  expect_identical(ggprint_rawr(already, interactive = TRUE), already)
})
