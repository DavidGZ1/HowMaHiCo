# Peptide length distribution: boxplot + count histogram

Peptide length distribution: boxplot + count histogram

## Usage

``` r
plot_peplength(input, title, ylimits = NULL, xlimits = NULL)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with a `Length` column.

- title:

  Plot title.

- ylimits, xlimits:

  Optional length-2 numeric vectors overriding the automatically derived
  axis limits (count-based `ylimits`, rounded up to the nearest 1000;
  length-based `xlimits`, rounded up to the nearest 10).

## Value

A `ggpubr`-arranged figure (boxplot above a count histogram) with the
title annotated above.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_peplength(pep_all, title = "All peptides")
} # }
```
