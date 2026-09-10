# Pearson correlation heatmap of log2(Area)

Plots a correlation matrix (e.g. `cor(., method = "pearson")`) with
[`ggcorrplot::ggcorrplot()`](https://rpkgs.datanovia.com/ggcorrplot/reference/ggcorrplot.html),
using a diverging red-white-blue gradient whose breaks/limits/midpoint
are derived directly from `mat`'s value range — a symmetric `[-1, 1]`
matrix gets the `(-1, 1, mid = 0)` scale, anything else gets a
`[0, 1]`-anchored scale with `mid = 0.7`.

## Usage

``` r
plot_corr(mat)
```

## Arguments

- mat:

  A correlation matrix (output of
  [`stats::cor()`](https://rdrr.io/r/stats/cor.html)).

## Value

A `ggcorrplot` ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_corr(cor(pep_all_log2area_tr, method = "pearson", use = "pairwise.complete.obs"))
} # }
```
