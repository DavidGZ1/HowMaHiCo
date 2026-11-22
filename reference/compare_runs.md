# Stack the quality scores of several runs into one table

One `01_mhc_overview` render scores one subset. `compare_runs()` stacks
the per-sample score tables of several renders (different experiments,
subsets, or the same QC standard measured over time) into a single long
table, so that they can be compared side by side with
[`summarise_runs()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_runs.md)
and
[`plot_run_trend()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_run_trend.md).

## Usage

``` r
compare_runs(runs, labels = NULL, order = c("input", "timestamp"))
```

## Arguments

- runs:

  A character vector of score-csv paths and/or results folders, a single
  [`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md)
  data frame, or a list of any of these. Names, when given, become the
  run labels.

- labels:

  Optional character vector of run labels, one per run after folders
  have been expanded. Overrides every other label source.

- order:

  `"input"` (default) keeps the runs in the order given; `"timestamp"`
  orders them by `render_timestamp` (oldest first), for a longitudinal
  view. Runs without a timestamp go last, with a warning.

## Value

The stacked score table: one row per (run, sample), with the leading
columns `Run` (a factor in run order), `SampleSet`, `Subset`,
`MHCclass`, `ThresholdMode`, `render_timestamp`, `package_version` and
`source_file`, followed by the score columns. Columns are the union over
runs: a metric one run lacks is `NA` there. Labels default to the input
names, then `SampleSet | Subset` from the companion params, then the
file name.

## Details

`runs` may mix three kinds of input:

- a **score csv** written by `01_mhc_overview` (`<Subset>_scores.csv`,
  or `scores.csv` when no `Subset` was set);

- a **results folder** holding one or more such files (e.g.
  `<FolderResults>/<Subset>`); every `*scores.csv` in it becomes a run;

- a **data frame** returned by
  [`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md).

For a csv, the companion `<Subset>_01_mhc_overview_input_params.csv`
that the same render writes next to it is read when present (for results
written before v0.27.0, the old
`<Subset>_05_quality_score_input_params.csv`), and its `SampleSet`,
`Subset`, `MHCclass`, `ThresholdMode`, `render_timestamp` and
`package_version` are attached as columns (`NA` when absent, and always
for data-frame input).

Composite scores are only comparable when the runs were scored the same
way, so a warning names the runs when `MHCclass` or `ThresholdMode`
differs between them: the class selects the threshold table, and
`"qc_relative"` thresholds are calibrated on each run's own QC samples.

## See also

[`summarise_runs()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_runs.md),
[`plot_run_trend()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_run_trend.md),
[`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md)

## Examples

``` r
if (FALSE) { # \dontrun{
runs <- compare_runs(c(jy = "3_results/dda_jy", plasma = "3_results/dda_plasma"))
summarise_runs(runs)
plot_run_trend(runs)
} # }
```
