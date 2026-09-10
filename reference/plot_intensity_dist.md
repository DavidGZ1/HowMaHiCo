# Intensity distribution per unit (normalization diagnostic)

Boxplots or densities of the log2 intensities of every unit. Comparing
the same plot before and after
[`normalize_quant()`](https://davidgz1.github.io/HowMaHiCo/reference/normalize_quant.md)
is what makes the chosen normalization auditable rather than a black
box.

## Usage

``` r
plot_intensity_dist(mat, coldata, type = c("box", "density"), title = NULL)
```

## Arguments

- mat:

  Numeric matrix of log2 intensities.

- coldata:

  Matching column metadata (`Unit`, `Condition`).

- type:

  `"box"` (default) or `"density"`.

- title:

  Plot title. Default `NULL`.

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_intensity_dist(mat_n, qm$coldata, title = "After median normalization")
} # }
```
