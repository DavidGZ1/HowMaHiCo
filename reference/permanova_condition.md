# Global permutation test of condition separation (PERMANOVA)

Answers "do the conditions separate at all?" before any per-feature
claim is made, using the distance-based pseudo-F of Anderson (2001): the
ratio of between-group to within-group sums of squared Euclidean
distances between samples, with a permutation null obtained by shuffling
the condition labels. It is non-parametric, makes no distributional
assumption, and needs no extra package. Only features quantified in
every column are used, since a distance must be computed on a common
feature set.

## Usage

``` r
permanova_condition(mat, coldata, n_perm = 999, seed = 1234)
```

## Arguments

- mat:

  Numeric matrix of (normalized, optionally imputed) log2 intensities,
  features x units.

- coldata:

  Column metadata from
  [`build_quant_matrix()`](https://davidgz1.github.io/HowMaHiCo/reference/build_quant_matrix.md).

- n_perm:

  Number of label permutations. Default `999`.

- seed:

  Random seed. Default `1234`.

## Value

A list with `F` (pseudo-F), `p_value`, `n_perm`, `n_features` (complete
features used) and `n_groups`; `NULL` with a warning when fewer than two
groups or no complete features are available.

## Details

The permutation p-value is bounded below by the number of distinct label
assignments: a 3-vs-3 comparison admits only `choose(6, 3) / 2 = 10` of
them, so its smallest attainable p-value is about `0.1`, however clean
the separation. Read the pseudo-F alongside the p-value in small
designs.

## Examples

``` r
if (FALSE) { # \dontrun{
permanova_condition(mat_n, qm$coldata)
} # }
```
