# Print a plot, skipping ones that were never built

The print-time counterpart to
[`ggsave_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/ggsave_rawr.md),
so a report chunk can unconditionally request a plot's display even when
it was conditionally skipped upstream. A bare symbol is looked up by
name in the **calling** environment; any other expression
(`plots[[nm]]`, a computed plot) is evaluated and judged by its value,
so `NULL` counts as "not generated".

## Usage

``` r
ggprint_rawr(input, interactive = FALSE)
```

## Arguments

- input:

  The object to print. When it is a bare variable name, that name is
  used to check existence rather than the value.

- interactive:

  Return the plot as an interactive plotly widget
  ([`plotly::ggplotly()`](https://rdrr.io/pkg/plotly/man/ggplotly.html))
  instead of a static ggplot. The report templates pass their
  `InteractivePlots` param here. Objects `ggplotly()` cannot convert
  (ggpubr composites, sequence logos, base-graphics heatmaps, objects
  that are already widgets) are returned unchanged, so a report never
  breaks for requesting interactivity.

  Only use this from an ordinary chunk: an htmlwidget printed from
  inside a `results='asis'` loop needs an explicit
  `tagList`/`knit_print` dance to get its dependencies attached, and
  silently renders empty without it.

## Value

The object, so a knitr chunk prints it; a plotly widget when
`interactive = TRUE` and the plot can be converted; invisible `NULL`
with a warning when it was never generated.

## Examples

``` r
if (FALSE) { # \dontrun{
ggprint_rawr(p_corr_log2area_all)
ggprint_rawr(p_pca_scores, interactive = TRUE)
} # }
```
