# Traffic-light heatmap of per-sample quality sub-scores

Renders the `score_<metric>` columns of a
[`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md)
table as a samples × metrics tile heatmap, filled on a red→amber→green
0–100 gradient and annotated with the rounded sub-score. Metric rows are
labelled with their human-readable names and QC samples are marked with
a trailing asterisk.

## Usage

``` r
plot_quality_heatmap(
  scores,
  thresholds = quality_thresholds_default(),
  drop_all_na = TRUE
)
```

## Arguments

- scores:

  Output of
  [`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md).

- thresholds:

  Scoring table used to label/order the metric rows (default
  [`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md)).

- drop_all_na:

  If `TRUE` (default), omit metrics whose sub-score is `NA` for every
  sample (dimensions undefined for this dataset, e.g. the depth metrics
  in `default` threshold mode or the DIA RT/IM errors for FragPipe). All
  rows are kept if every metric would be dropped.

## Value

A ggplot2 tile heatmap.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_quality_heatmap(score_sample_quality(pep_all, c(8, 13), "MHC1"))
} # }
```
