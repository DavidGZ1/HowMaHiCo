# Data completeness of a quantitative matrix

Two views of the missingness structure that governs every downstream
test: `type = "unit"` shows how many features are quantified in each
unit (sample or bioreplicate), `type = "feature"` how many units each
feature is quantified in — the distribution that the
[`filter_quant()`](https://davidgz1.github.io/HowMaHiCo/reference/filter_quant.md)
cut-off acts on.

## Usage

``` r
plot_completeness(mat, coldata, type = c("unit", "feature"))
```

## Arguments

- mat:

  Numeric matrix from
  [`build_quant_matrix()`](https://davidgz1.github.io/HowMaHiCo/reference/build_quant_matrix.md).

- coldata:

  Matching column metadata (`Unit`, `Condition`).

- type:

  `"unit"` (default) or `"feature"`.

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_completeness(qm$mat, qm$coldata, type = "unit")
} # }
```
