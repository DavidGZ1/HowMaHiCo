# Clustered heatmap of a numeric matrix, saved directly to png

Wraps
[`gplots::heatmap.2()`](https://talgalili.github.io/gplots/reference/heatmap.2.html)
with complete-linkage/Euclidean clustering, a diverging RdBu palette
sized to the data range, row side-colors from
[`cutree()`](https://rdrr.io/r/stats/cutree.html) cluster assignment,
and column side-colors derived from `annotation`'s `group` column — then
writes the result straight to `file` as a png (the function has no
return value; it is called for this side effect).

## Usage

``` r
plot_heatmap(
  mat,
  annotation,
  level,
  group,
  n_clust = 5,
  width = 24,
  height = 24,
  units = "cm",
  res = 100,
  keysize = 0.9,
  file,
  ...
)
```

## Arguments

- mat:

  Numeric matrix to cluster and plot (e.g. output of
  [`get_mat_log2area()`](https://davidgz1.github.io/HowMaHiCo/reference/get_mat_log2area.md)).

- annotation:

  Annotation data frame; must contain the `level` and `group` columns
  (`level` matches `mat`'s column names, `group` colors them).

- level:

  Column (string) in `annotation` matching `mat`'s columns.

- group:

  Column (string) in `annotation` used to color columns.

- n_clust:

  Number of row clusters to cut the dendrogram into.

- width, height, units, res:

  Passed to [`grDevices::png()`](https://rdrr.io/r/grDevices/png.html).

- keysize:

  Passed to
  [`gplots::heatmap.2()`](https://talgalili.github.io/gplots/reference/heatmap.2.html).

- file:

  Output png file path.

- ...:

  Additional arguments passed to
  [`gplots::heatmap.2()`](https://talgalili.github.io/gplots/reference/heatmap.2.html).

## Value

Invisible `NULL`; called for its side effect of writing `file`.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_heatmap(mat_log2area, annotation, level = "Sample", group = "Condition",
             file = file.path("4_figures", "hm_pep_all_log2area_br_nonscaled.png"))
} # }
```
