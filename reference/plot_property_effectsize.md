# Effect sizes of the between-condition comparison

Tile map of
[`cliffs_delta()`](https://davidgz1.github.io/HowMaHiCo/reference/cliffs_delta.md)
per descriptor (or residue) and contrast, outlined where the BH-adjusted
p-value passes `fdr`. Cliff's delta is scale-free, so descriptors on
different units (GRAVY, pI, molecular weight) share one axis and can be
ranked against each other — which a table of median differences cannot
do.

## Usage

``` r
plot_property_effectsize(stats, fdr = NULL, title = NULL)
```

## Arguments

- stats:

  Output of
  [`compare_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_pepchem.md)
  or
  [`compare_aa_frequency()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_aa_frequency.md).

- fdr:

  Significance cut-off; `NULL` uses the value recorded on `stats`.

- title:

  Plot title. `NULL` (default) picks a generic one.

## Value

A ggplot object, or `NULL` when `stats` has no rows.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_property_effectsize(compare_pepchem(props))
} # }
```
