# Peptide mass distribution: boxplot + density histogram with apex annotation

Finds the distribution apex (mode of the kernel density estimate, per
[http://ianmadd.github.io/pages/PeakDensityDistribution.html](http://ianmadd.github.io/pages/PeakDensityDistribution.md))
and annotates it on the histogram panel.

## Usage

``` r
plot_pepmass(input, title, xlimits = NULL)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with a `Mass` column.

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
plot_pepmass(pep_all, title = "All peptides")
} # }
```
