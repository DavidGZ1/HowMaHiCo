# Compare quality metrics across runs

Plots the stacked score table from
[`compare_runs()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_runs.md)
with one panel per metric (free y axes) and the runs on the x axis, in
their factor order: input order, or render time for
`compare_runs(order = "timestamp")`. Each sample is a point, and QC
samples are drawn as triangles. `type = "box"` adds a box per run.
`type = "line"` instead joins the run medians, which reads as a trend
when the runs are repeated measurements of the same standard.

## Usage

``` r
plot_run_trend(
  runs_tbl,
  metrics = c("composite_score", "frac_in_window", "n_unique_pep_in_window"),
  type = c("box", "line"),
  color_by = NULL
)
```

## Arguments

- runs_tbl:

  Output of
  [`compare_runs()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_runs.md).

- metrics:

  Metric columns to plot (default: composite score, length-window
  fidelity and in-window depth). Panels are labelled with the metric
  names of
  [`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md).

- type:

  `"box"` (default) or `"line"`.

- color_by:

  Optional column to colour the points by (e.g. `"Condition"`, which
  `05_quality_score` writes into its score csv). `NULL` for none.

## Value

A ggplot2 object.

## Examples

``` r
if (FALSE) { # \dontrun{
runs <- compare_runs(c("3_results/qc_week1", "3_results/qc_week2"),
                     order = "timestamp")
plot_run_trend(runs, type = "line")
} # }
```
