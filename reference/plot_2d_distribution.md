# 2D binned heatmap for any two continuous peptide properties

2D binned heatmap for any two continuous peptide properties

## Usage

``` r
plot_2d_distribution(
  input,
  x_var,
  y_var,
  binwidth,
  title,
  x_lab = x_var,
  y_lab = y_var,
  ncol = 3
)
```

## Arguments

- input:

  A `pep_all`-shaped data frame.

- x_var, y_var:

  Column names (strings) for the x and y axes.

- binwidth:

  Length-2 numeric `c(x_width, y_width)` passed to
  [`ggplot2::geom_bin_2d()`](https://ggplot2.tidyverse.org/reference/geom_bin_2d.html).

- title:

  Plot title string.

- x_lab, y_lab:

  Axis labels; default to `x_var`/`y_var`.

- ncol:

  Number of facet columns.

## Value

A ggplot2 heatmap.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_2d_distribution(pep_all, "m_z", "invk0", c(10, 0.025), "All peptides",
                     x_lab = "m/z", y_lab = "1/k0", ncol = 3)
} # }
```
