# Peptide length distribution: boxplot + density histogram

Density-axis counterpart to
[`plot_peplength()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_peplength.md)
— same boxplot-over-histogram layout, but the lower panel shows
`..density..` rather than raw counts (and so has no `ylimits`).

## Usage

``` r
plot_peplength_dens(input, title, ylimits = NULL, xlimits = NULL)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with a `Length` column.

- title:

  Plot title.

- ylimits, xlimits:

  Optional length-2 numeric vectors overriding the automatically derived
  axis limits. `ylimits` is currently unused (kept for signature parity
  with
  [`plot_peplength()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_peplength.md)).

## Value

A `ggpubr`-arranged figure (boxplot above a density histogram) with the
title annotated above.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_peplength_dens(pep_all, title = "All peptides")
} # }
```
