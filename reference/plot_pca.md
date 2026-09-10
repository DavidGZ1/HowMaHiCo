# Principal component analysis of a quantitative matrix

Unsupervised overview of the quantitative data: whether the units group
by condition at all, before any per-feature claim is made. The PCA runs
on complete features only (a rotation cannot be computed with missing
values), so the number of features used is reported in the subtitle.

## Usage

``` r
plot_pca(
  mat,
  coldata,
  type = c("scores", "scree", "loadings"),
  pc = c(1, 2),
  n_loadings = 15
)
```

## Arguments

- mat:

  Numeric matrix of log2 intensities (optionally imputed).

- coldata:

  Matching column metadata (`Unit`, `Condition`).

- type:

  `"scores"` (default, PC1 vs PC2), `"scree"` (explained variance) or
  `"loadings"` (features contributing most to `pc`).

- pc:

  Principal components to display, length 2 for `"scores"` (default
  `c(1, 2)`); the first element selects the component for `"loadings"`.

- n_loadings:

  Number of features shown by `type = "loadings"`. Default `15`.

## Value

A ggplot object, or `NULL` (with a warning) when fewer than two complete
features or fewer than three units are available.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_pca(mat_n, qm$coldata)
} # }
```
