# Boxplot of Score or mass error per Condition and charge

Creates a `ChargeSimple` column ("+1" vs "\>= +2"), then renders a
[`ggpubr::ggboxplot()`](https://rpkgs.datanovia.com/ggpubr/reference/ggboxplot.html)
faceted by charge group.

## Usage

``` r
plot_qc_box(df, y_var, title)
```

## Arguments

- df:

  A `pep_all`-shaped data frame with `Charge` and `y_var` columns.

- y_var:

  Column name (string) to plot on the y-axis, e.g. `"Score"` or `"ppm"`.

- title:

  Plot title.

## Value

A `ggpubr` boxplot figure, faceted by `ChargeSimple`.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_qc_box(pep_all, "Score", "Score boxplot")
plot_qc_box(pep_all, "ppm",   "Mass error boxplot")
} # }
```
