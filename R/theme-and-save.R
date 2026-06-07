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
#' @keywords internal
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

#' Save a ggplot to the figures folder, skipping plots that were never built
#'
#' Looks up `input` by the name it was called with (via `deparse(substitute())`)
#' and only calls [ggplot2::ggsave()] if an object of that name exists in the
#' calling environment — this lets report chunks unconditionally call
#' `ggsave_rawr(p_some_plot, "some_plot")` even when `p_some_plot` was
#' conditionally skipped upstream (e.g. no non-NA correlation to plot), without
#' erroring.
#'
#' @param input The plot object to save (NSE: its variable name is used to
#'   check existence, not its value).
#' @param file Output file name, without extension; saved as `<file>.png`
#'   under `4_figures/`.
#' @param width,height Figure dimensions in cm, passed to [ggplot2::ggsave()].
#'
#' @return Invisible `NULL`; called for its side effect of writing a png (or
#'   warning that it was skipped).
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' ggsave_rawr(p_peplength_all, "peplength_all")
#' }
ggsave_rawr <- function(input, file, width = 8, height = 10) {
  if(exists(deparse(substitute(input))) == TRUE){
    ggplot2::ggsave(file.path("4_figures", paste0(file, ".png")), input, device = "png",
                    scale = 1, width = width, height = height, units = "cm")
  }else{
    warning(paste0(file, ".png was not saved because the plot was not generated"))
  }
}

#' Print a plot, skipping ones that were never built
#'
#' Looks up `input` by the name it was called with (via `deparse(substitute())`)
#' and only prints it if an object of that name exists in the calling
#' environment — the print-time counterpart to [ggsave_rawr()], so a report
#' chunk can unconditionally request a plot's display even when it was
#' conditionally skipped upstream.
#'
#' @param input The object to print (NSE: its variable name is used to check
#'   existence, not its value).
#'
#' @return The printed object (invisibly), or a warning if it does not exist.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' ggprint_rawr(p_corr_log2area_all)
#' }
ggprint_rawr <- function(input) {
  if(exists(deparse(substitute(input))) == TRUE){
    input
  }else{
    warning(paste0(deparse(substitute(input)), " was not generated"))
  }
}
