# Heatmap of a quantitative matrix, clustered or in annotation order

ggplot2 tile heatmap of the most variable features, drawn either with
hierarchical clustering of both dimensions (`cluster = TRUE`) or in the
order given by the annotation table (`cluster = FALSE`) — the two views
answer different questions: whether the data cluster by condition on
their own, and how the conditions look side by side as designed. Unlike
[`plot_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_heatmap.md),
which writes a png through
[`gplots::heatmap.2`](https://talgalili.github.io/gplots/reference/heatmap.2.html),
this returns a ggplot object that can be printed inside a knitted
tabset.

## Usage

``` r
plot_quant_heatmap(
  mat,
  coldata,
  cluster = TRUE,
  top_n = 500,
  center_rows = TRUE,
  title = NULL
)
```

## Arguments

- mat:

  Numeric matrix of log2 intensities.

- coldata:

  Matching column metadata (`Unit`, `Condition`).

- cluster:

  Cluster rows and columns (`TRUE`, default) or keep the annotation
  order (`FALSE`).

- top_n:

  Number of most variable features to show. Default `500`.

- center_rows:

  Subtract the feature mean, so the colour encodes the log2 ratio to the
  feature average rather than absolute abundance. Default `TRUE`.

- title:

  Plot title. Default `NULL` (auto-generated).

## Value

A ggplot object, or `NULL` (with a warning) when the matrix is empty.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_quant_heatmap(mat_n, qm$coldata, cluster = TRUE, top_n = 300)
} # }
```
