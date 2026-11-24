# Peptide ID pseudomobilogram: count vs 1/k0, faceted by Condition

Ion-mobility analogue of
[`plot_pseudochromatogram()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pseudochromatogram.md):
bins peptides by their `invk0` (1/k0) value and plots the per-bin
peptide count, coloured by count (a density gradient), faceted by
Condition.

## Usage

``` r
plot_pseudomobilogram(input, title, ncol = 3, binwidth = 0.05)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with `invk0`, `Peptide`, `Condition`.

- title:

  Plot title string.

- ncol:

  Number of facet columns.

- binwidth:

  1/k0 bin width. Default `0.05`.

## Value

A ggplot2 bar chart.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_pseudomobilogram(pep_all, "All peptides identified", ncol = 3)
} # }
```
