# Presence/absence map of a quantitative matrix

Tile map of quantified (dark) versus missing (light) values, features
sorted by completeness, so a block of condition-specific missingness is
visible at a glance and can be told apart from random dropout.

## Usage

``` r
plot_missing_heatmap(mat, coldata, max_features = 3000)
```

## Arguments

- mat:

  Numeric matrix from
  [`build_quant_matrix()`](https://davidgz1.github.io/HowMaHiCo/reference/build_quant_matrix.md).

- coldata:

  Matching column metadata (`Unit`, `Condition`).

- max_features:

  Maximum number of features drawn (the most complete ones are kept,
  with a note in the subtitle). Default `3000`.

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_missing_heatmap(qm$mat, qm$coldata)
} # }
```
