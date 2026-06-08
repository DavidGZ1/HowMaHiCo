# Heatmap of PTM counts or proportions for length-filtered peptides

Cleans PTM annotation strings, splits multi-PTM entries (`;`/`,`
delimited), and renders a
[`ggplot2::geom_tile()`](https://ggplot2.tidyverse.org/reference/geom_tile.html)
heatmap of PTM counts or proportions per Condition. All data preparation
is handled internally — only `pep_short` (the length-filtered peptide
table) is needed.

## Usage

``` r
plot_ptm_heatmap(
  pep_short,
  type = c("count", "proportion"),
  shortpep_range = c(8, 13)
)
```

## Arguments

- pep_short:

  Length-filtered `pep_all`-shaped data frame (e.g. the `pep_short`
  object created in the report's `initialize` chunk).

- type:

  `"count"` (default) for absolute peptide counts per PTM, or
  `"proportion"` for the percentage of PTM-modified vs total peptides.

- shortpep_range:

  Length-2 numeric vector `c(min, max)` — used only for the
  `"proportion"` subtitle (the denominator is computed directly from
  `pep_short`).

## Value

A ggplot2 tile heatmap.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_ptm_heatmap(pep_short, type = "count")
plot_ptm_heatmap(pep_short, type = "proportion", shortpep_range = c(8, 13))
} # }
```
