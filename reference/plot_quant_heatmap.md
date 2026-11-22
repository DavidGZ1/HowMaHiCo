# Heatmap of a quantitative matrix, clustered or in annotation order

ggplot2 tile heatmap of the most variable features, drawn either with
hierarchical clustering of both dimensions (`cluster = TRUE`) or in the
order given by the annotation table (`cluster = FALSE`) — the two views
answer different questions: whether the data cluster by condition on
their own, and how the conditions look side by side as designed. Unlike
[`plot_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_heatmap.md),
which writes a png through
[`gplots::heatmap.2`](https://talgalili.github.io/gplots/reference/heatmap.2.html),
this returns an object that can be printed inside a knitted tabset.

## Usage

``` r
plot_quant_heatmap(
  mat,
  coldata,
  cluster = TRUE,
  top_n = 500,
  center_rows = TRUE,
  n_clusters = 4,
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

- n_clusters:

  Number of feature clusters drawn in the clustered view (capped at the
  number of features). Default `4`.

- title:

  Plot title. Default `NULL` (auto-generated).

## Value

For `cluster = FALSE` (or when clustering is not possible: fewer than
three features or units), a ggplot object. For the clustered view, a
[`ggpubr::ggarrange()`](https://rpkgs.datanovia.com/ggpubr/reference/ggarrange.html)
composite (dendrogram + Condition bar over the heatmap) carrying
`attr(, "clusters")`, a data frame with `Feature` and `Cluster` in
display order. `NULL` (with a warning) when the matrix is empty.

## Details

The clustered view makes the clustering visible rather than only using
it to order the tiles: the unit (column) dendrogram is drawn above a
Condition colour bar, the feature (row) dendrogram on the left, and the
features are cut into `n_clusters` groups
([`stats::cutree()`](https://rdrr.io/r/stats/cutree.html)), separated by
white lines and labelled `C1`, `C2`, ... from top to bottom. The
feature-to-cluster assignment is attached as `attr(p, "clusters")` so a
report can export it.

## Examples

``` r
if (FALSE) { # \dontrun{
p <- plot_quant_heatmap(mat_n, qm$coldata, cluster = TRUE, top_n = 300)
head(attr(p, "clusters"))
} # }
```
