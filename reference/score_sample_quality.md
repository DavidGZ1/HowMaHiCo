# Score immunopeptidomics samples for overall quality

Computes a per-sample composite quality score (and a traffic-light
category) from `pep_all`, combining several interpretable dimensions:
length-window fidelity, 9-mer dominance, anchor-motif clarity,
non-tryptic specificity, charge plausibility, depth, and mass accuracy.
Each raw metric
([`qc_metrics_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/qc_metrics_by_sample.md))
is mapped to a 0-100 sub-score
([`score_curve()`](https://davidgz1.github.io/HowMaHiCo/reference/score_curve.md))
against either built-in defaults
([`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md))
or thresholds calibrated from tagged QC samples
([`calibrate_thresholds_from_qc()`](https://davidgz1.github.io/HowMaHiCo/reference/calibrate_thresholds_from_qc.md)).
The composite is the weighted mean of the *available* sub-scores, so
undefined dimensions (e.g. MHC-II anchors, DIA-NN `ppm`) drop out
instead of penalising the sample.

## Usage

``` r
score_sample_quality(
  pep_all,
  shortpep_range = c(8, 13),
  mhcclass = "MHC1",
  qc_samples = NULL,
  threshold_mode = c("default", "qc_relative"),
  thresholds = NULL,
  weights = NULL
)
```

## Arguments

- pep_all:

  A unified `pep_all` data frame.

- shortpep_range:

  Length-2 numeric `c(min, max)` ligand-length window.

- mhcclass:

  `"MHC1"`, `"MHC1_mouse"` (7-11 AA window, 8/9-mer canonical lengths)
  or `"MHC2"`; also selects the default threshold table.

- qc_samples:

  Optional character vector of `Sample` values flagged as QC controls
  (e.g. from an annotation `QC` column). Used to mark samples and, when
  `threshold_mode = "qc_relative"`, to calibrate thresholds.

- threshold_mode:

  `"default"` (absolute literature thresholds) or `"qc_relative"`
  (thresholds derived from `qc_samples`). `"qc_relative"` falls back to
  defaults if no QC samples are supplied.

- thresholds:

  Optional scoring table overriding the class-appropriate
  [`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md)
  (which is used when this is `NULL`).

- weights:

  Optional named numeric vector overriding the `weight` column of
  `thresholds` (names = metric names).

## Value

A data frame with one row per `Sample`: the raw metrics, a
`score_<metric>` column per dimension, `composite_score`, `category`,
and `is_QC`. Sorted by descending `composite_score`.

## Examples

``` r
if (FALSE) { # \dontrun{
score_sample_quality(pep_all, c(8, 13), "MHC1")
score_sample_quality(pep_all, c(8, 13), "MHC1",
                     qc_samples = c("QC_A"), threshold_mode = "qc_relative")
} # }
```
