# Filter a quantitative matrix to testable features

Keeps the features quantified in at least `min_per_group` units of **at
least one** condition. A feature observed once cannot support a variance
estimate, and in DDA it is dominated by stochastic precursor sampling;
requiring the minimum in only one group (rather than all) deliberately
retains the condition-exclusive ligands, which the presence/absence
track
([`test_detection()`](https://davidgz1.github.io/HowMaHiCo/reference/test_detection.md))
tests instead.

## Usage

``` r
filter_quant(mat, coldata, min_per_group = 2)
```

## Arguments

- mat:

  Numeric matrix from
  [`build_quant_matrix()`](https://davidgz1.github.io/HowMaHiCo/reference/build_quant_matrix.md).

- coldata:

  The matching `coldata` data frame (needs `Unit`, `Condition`).

- min_per_group:

  Minimum number of units with a quantified value in at least one
  condition. Default `2`.

## Value

The filtered matrix, with attributes `n_dropped` (integer) and `dropped`
(character vector of removed feature names).

## Examples

``` r
if (FALSE) { # \dontrun{
mat_f <- filter_quant(qm$mat, qm$coldata, min_per_group = 2)
attr(mat_f, "n_dropped")
} # }
```
