# Stacked bar chart of total ID counts per Condition, split by length range

Plots `n_<level>` (`level` one of
`"Peptides"`/`"Sequences"`/`"Proteins"`) against `Condition`, filled by
`Length_range`, with a `"Total=..."` annotation above each bar reporting
the `"All peptides"` row's count.

## Usage

``` r
plot_bp_count_length(df, level, lim_level, shortpep_range = c(8, 13))
```

## Arguments

- df:

  A counts data frame with `Condition`, `Length_range`, and an
  `n_<level>` column (e.g. the output of
  `count_ids_condition_bylengthrange`- style summaries, including an
  `"All peptides"` total row per `Condition`).

- level:

  One of `"Peptides"`, `"Sequences"`, `"Proteins"` — selects the
  `n_<level>` column to plot and labels the y-axis.

- lim_level:

  Upper y-axis limit (e.g. looked up from a `count_lim` table by
  `Level`/`"Limit_total"`).

- shortpep_range:

  Length-2 vector `c(min, max)` used to label the `"others"`
  `Length_range` class as `"< min OR > max AAs"`.

## Value

A `ggpubr` bar chart (`ggbarplot`) with per-bar count labels, a
`"Total=..."` annotation, and a viridis fill scale.

## Details

The original report-inline version closed over three chunk-local globals
(`count_lim`, `counts_size_total`, `shortpep_range`); this migrated
version threads them through as explicit arguments — `lim_level` (the
y-axis upper limit looked up from `count_lim` by the caller) and
`shortpep_range` (defaulted to the standard 8-13 AA HLA-I window). The
`counts_size_total` closure reference is replaced by `df` itself, since
every call site already passes `counts_size_total` as `df` — these were
always the same object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_bp_count_length(counts_size_total, "Peptides", lim_level = 50000, shortpep_range = c(8, 13))
} # }
```
