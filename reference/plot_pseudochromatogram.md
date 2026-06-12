# Peptide ID pseudochromatogram: count vs RT, faceted by Condition

Peptide ID pseudochromatogram: count vs RT, faceted by Condition

## Usage

``` r
plot_pseudochromatogram(input, title, ncol = 3)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with `RT`, `Peptide`, `Condition`.

- title:

  Plot title string.

- ncol:

  Number of facet columns.

## Value

A ggplot2 bar chart.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_pseudochromatogram(pep_all, "All peptides identified", ncol = 3)
} # }
```
