# Violin + overlaid boxplot of Score or mass error per Condition and charge

Creates a `ChargeSimple` column ("+1" vs "\>= +2"), then renders a
[`ggpubr::ggviolin()`](https://rpkgs.datanovia.com/ggpubr/reference/ggviolin.html)
faceted by charge group with an overlaid boxplot and error bars.

## Usage

``` r
plot_qc_violin(df, y_var, title)
```

## Arguments

- df:

  A `pep_all`-shaped data frame with `Charge` and `y_var` columns.

- y_var:

  Column name (string) to plot on the y-axis, e.g. `"Score"` or `"ppm"`.

- title:

  Plot title.

## Value

A `ggpubr` violin/boxplot figure, faceted by `ChargeSimple`.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_qc_violin(pep_all, "Score", "Score distribution, and boxplot")
plot_qc_violin(pep_all, "ppm",   "Mass error distribution, and boxplot")
} # }
```
