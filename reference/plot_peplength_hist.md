# Peptide length histogram faceted by Condition

Faceted histogram of peptide lengths across conditions, with bars
coloured by whether each length falls within `shortpep_range` ("X to Y
AAs") or outside ("others"). Replaces the
[`plot_peplength_dens()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_peplength_dens.md) +
`lapply` + `ggarrange` approach in the report with a single `facet_wrap`
call.

## Usage

``` r
plot_peplength_hist(
  input,
  shortpep_range = c(8, 13),
  type = c("density", "count"),
  palette = NULL,
  xlimits = c(5, 25)
)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with `Length` and `Condition` columns.
  Typically `pep_all_unique` (one row per peptide–condition pair).

- shortpep_range:

  Length-2 integer vector giving the inclusive range `[min, max]` that
  defines the "in-range" fill category. Default `c(8, 13)`.

- type:

  One of `"density"` (y-axis = relative frequency) or `"count"` (y-axis
  = raw count). Matched via
  [`match.arg()`](https://rdrr.io/r/base/match.arg.html).

- palette:

  Named character vector of length 2 mapping the range label
  (`"X to Y AAs"`) and `"others"` to colours. When `NULL`, falls back to
  [`ggplot2::scale_fill_viridis_d()`](https://ggplot2.tidyverse.org/reference/scale_viridis.html).

- xlimits:

  Length-2 numeric vector for the x-axis limits. Default `c(5, 25)`.

## Value

A `ggplot` object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_peplength_hist(pep_all_unique, shortpep_range = c(8, 13),
                    type = "density", palette = c("8 to 13 AAs" = "#fde725",
                                                   others = "#440154"))
} # }
```
