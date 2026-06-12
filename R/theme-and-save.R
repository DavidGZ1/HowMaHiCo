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
#' @export
#'
#' @examples
#' \dontrun{
#' ggprint_rawr(p_corr_log2area_all)
#' }
ggprint_rawr <- function(input) {
  if(exists(deparse(substitute(input)))){
    input
  }else{
    warning(paste0(deparse(substitute(input)), " was not generated"))
  }
}
