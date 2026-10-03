# Was the plot behind `expr` actually built?
#
# Shared by ggprint_rawr() and ggsave_rawr(), which both let a report chunk name
# a plot that an upstream chunk may have skipped.
#
# `caller` is the frame the plot name has to be resolved in. Passing it matters:
# bare exists("p_x") searches from the *calling function's own* frame outwards
# through its lexical parents -- for these two exported helpers that is the
# HowMaHiCo namespace, then globalenv, and NEVER the report's knit environment
# (rmarkdown renders in new.env(parent = globalenv())). Every lookup from a
# report therefore used to fail, so ggsave_rawr() silently saved nothing under
# PlotsSave = TRUE and ggprint_rawr() silently dropped the plot it was asked to
# display.
#
# Only a bare symbol gets the existence check; anything else (plots[[nm]], a
# computed plot) is evaluated in `caller` and judged by value, so the idiomatic
# `for (nm in names(plots)) ggsave_rawr(plots[[nm]], ...)` loop works too.
.plot_was_built <- function(expr, caller) {
  if (is.symbol(expr))
    return(exists(deparse(expr), envir = caller) &&
             !is.null(eval(expr, envir = caller)))
  value <- tryCatch(eval(expr, envir = caller), error = function(e) NULL)
  !is.null(value)
}

#' HowMaHiCo's shared ggplot theme
#'
#' A [ggpubr::theme_pubr()] variant used across every report plot: blank facet
#' strip backgrounds, small strip/axis/legend text, and a bold plot title — all
#' sized to fit the report's compact figure layout.
#'
#' @param base_size Base font size, passed to [ggpubr::theme_pubr()].
#'
#' @return A ggplot2 theme object, addable to a plot with `+`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ggplot(pep_all, aes(Length)) + geom_histogram() + theme_rawr()
#' }
theme_rawr <- function(base_size = 8){
  ggpubr::theme_pubr(base_size = base_size, legend = "top") +
    ggplot2::theme(strip.background = ggplot2::element_blank(),
                   strip.text = ggplot2::element_text(size = 8),
                   axis.text.x = ggplot2::element_text(size = 8),
                   legend.key.size = ggplot2::unit(0.7, "lines"),
                   plot.title = ggplot2::element_text(face = "bold", size = 8))
}

#' HowMaHiCo's unified ggplot theme
#'
#' A [ggplot2::theme_minimal()] variant applied consistently across all package
#' plot functions and report templates. Standardises strip/axis/legend/title
#' font sizes and sets a white plot background.
#'
#' @param base_size Base font size (points). Default 8.
#'
#' @return A ggplot2 theme object, addable to a plot with `+`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ggplot(pep_all, aes(Length)) + geom_histogram() + theme_howmahico()
#' }
theme_howmahico <- function(base_size = 8) {
  ggplot2::theme_classic(base_size = base_size) +
    ggplot2::theme(
      strip.background = ggplot2::element_blank(),
      strip.text       = ggplot2::element_text(size = base_size, face = "bold"),
      axis.text.x      = ggplot2::element_text(size = base_size - 2),
      axis.text.y      = ggplot2::element_text(size = base_size - 2),
      axis.title       = ggplot2::element_text(size = base_size),
      legend.key.size  = ggplot2::unit(0.7, "lines"),
      legend.text      = ggplot2::element_text(size = base_size - 2),
      legend.title     = ggplot2::element_text(size = base_size - 1),
      plot.title       = ggplot2::element_text(face = "bold", size = base_size),
      plot.background  = ggplot2::element_rect(fill = "white", color = NA),
      legend.position  = "top"
    )
}

# Plot classes ggplotly() cannot convert: ggpubr composites (plot_peplength_dens,
# plot_pepmass, ...), sequence logos, and anything already an htmlwidget. Checked
# so an interactive = TRUE report degrades to the static plot instead of erroring
# or rendering an empty widget.
.ggplotly_incompatible <- c("ggarrange", "ggseqlogo", "patchwork", "gtable",
                            "htmlwidget", "plotly")

# Can this object be handed to plotly::ggplotly()?
.is_ggplotly_safe <- function(x) {
  inherits(x, "ggplot") && !inherits(x, .ggplotly_incompatible, which = FALSE)
}

#' Print a plot, skipping ones that were never built
#'
#' The print-time counterpart to [ggsave_rawr()], so a report chunk can
#' unconditionally request a plot's display even when it was conditionally
#' skipped upstream. A bare symbol is looked up by name in the **calling**
#' environment; any other expression (`plots[[nm]]`, a computed plot) is
#' evaluated and judged by its value, so `NULL` counts as "not generated".
#'
#' @param input The object to print. When it is a bare variable name, that name
#'   is used to check existence rather than the value.
#' @param interactive Return the plot as an interactive plotly widget
#'   ([plotly::ggplotly()]) instead of a static ggplot. The report templates pass
#'   their `InteractivePlots` param here. Objects `ggplotly()` cannot convert
#'   (ggpubr composites, sequence logos, base-graphics heatmaps, objects that are
#'   already widgets) are returned unchanged, so a report never breaks for
#'   requesting interactivity.
#'
#'   Only use this from an ordinary chunk: an htmlwidget printed from inside a
#'   `results='asis'` loop needs an explicit `tagList`/`knit_print` dance to get
#'   its dependencies attached, and silently renders empty without it.
#'
#' @return The object, so a knitr chunk prints it; a plotly widget when
#'   `interactive = TRUE` and the plot can be converted; invisible `NULL` with a
#'   warning when it was never generated.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ggprint_rawr(p_corr_log2area_all)
#' ggprint_rawr(p_pca_scores, interactive = TRUE)
#' }
ggprint_rawr <- function(input, interactive = FALSE) {
  if (!.plot_was_built(substitute(input), parent.frame())) {
    warning(paste0(deparse(substitute(input)), " was not generated"))
    return(invisible(NULL))
  }
  if (isTRUE(interactive) && .is_ggplotly_safe(input))
    return(plotly::ggplotly(input))
  input
}
