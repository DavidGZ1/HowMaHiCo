# Derive QC-relative thresholds from tagged quality-control samples

Replaces the absolute green/amber thresholds of a scoring table with
values anchored on the experiment's own QC sample(s): green is set to
the QC median of each metric and amber to that median relaxed by `slack`
(downward for `higher_better` metrics, upward for `lower_better`). This
is what lets the score be calibrated without any external benchmark
dataset. Metrics whose QC median is `NA` keep their default thresholds.

## Usage

``` r
calibrate_thresholds_from_qc(
  metrics,
  qc_samples,
  thresholds = quality_thresholds_default(),
  slack = 0.2
)
```

## Arguments

- metrics:

  Output of
  [`qc_metrics_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/qc_metrics_by_sample.md).

- qc_samples:

  Character vector of `Sample` values flagged as QC controls.

- thresholds:

  A scoring table to recalibrate (default
  [`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md));
  its `direction`/`weight`/`label` are kept.

- slack:

  Fractional tolerance for the amber band (default `0.2`, i.e. amber =
  green × 0.8 for higher-better, green × 1.2 for lower-better).

## Value

The `thresholds` table with `green`/`amber` recomputed from the QC
samples where possible.

## Examples

``` r
if (FALSE) { # \dontrun{
m <- qc_metrics_by_sample(pep_all, c(8, 13), "MHC1")
calibrate_thresholds_from_qc(m, qc_samples = c("QC_A", "QC_B"))
} # }
```
