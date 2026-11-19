# Summarise stacked quality scores per run

Condenses the output of
[`compare_runs()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_runs.md)
to one row per (run, metric): the number of samples with a value, the
median and the inter-quartile range, plus the number of samples per
traffic-light category of the run.

## Usage

``` r
summarise_runs(runs_tbl, metrics = NULL)
```

## Arguments

- runs_tbl:

  Output of
  [`compare_runs()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_runs.md).

- metrics:

  Metric columns to summarise. Default: `composite_score` and every raw
  metric of
  [`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md)
  present in `runs_tbl`.

## Value

A data frame with columns `Run`, `metric`, `label`, `n`, `median`,
`q25`, `q75`, `n_Pass`, `n_Warning`, `n_Fail`.

## Examples

``` r
if (FALSE) { # \dontrun{
summarise_runs(compare_runs(c("3_results/dda_jy", "3_results/dda_plasma")))
} # }
```
