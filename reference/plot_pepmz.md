# Peptide m/z distribution: boxplot + density histogram with apex annotation

`m_z` counterpart to
[`plot_pepmass()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pepmass.md)
— identical layout and apex-finding logic, applied to the `m_z` column
instead of `Mass`.

## Usage

``` r
plot_pepmz(input, title, xlimits = NULL)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with an `m_z` column.

- title:

  Plot title.

- xlimits:

  Optional length-2 numeric vector overriding the x-axis limits on both
  panels.

## Value

A `ggpubr`-arranged figure (boxplot above a density histogram with an
"Apex = ..." annotation) with the title annotated above.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_pepmz(pep_all, title = "All peptides")
} # }
```
