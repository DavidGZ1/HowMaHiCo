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
  shortpep_range = c(8, 13),
  translate = TRUE,
  reference = ptm_reference()
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

- translate:

  Translate the PTM tokens to readable modification names via
  [`translate_ptm()`](https://davidgz1.github.io/HowMaHiCo/reference/translate_ptm.md)
  (default `TRUE`). The raw tokens are engine-specific — UniMod
  accessions for DIA-NN, delta masses for FragPipe and PEAKS — so
  without this the same modification reads differently per engine. Set
  `FALSE` to plot the tokens as the search engine wrote them.

- reference:

  Modification lookup table passed to
  [`translate_ptm()`](https://davidgz1.github.io/HowMaHiCo/reference/translate_ptm.md);
  defaults to
  [`ptm_reference()`](https://davidgz1.github.io/HowMaHiCo/reference/ptm_reference.md).
  Ignored when `translate = FALSE`.

## Value

A ggplot2 tile heatmap.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_ptm_heatmap(pep_short, type = "count")
plot_ptm_heatmap(pep_short, type = "proportion", shortpep_range = c(8, 13))
plot_ptm_heatmap(pep_short, translate = FALSE)   # raw engine tokens
} # }
```
