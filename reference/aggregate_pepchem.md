# Aggregate per-sample descriptor summaries to Conditions

The second aggregation step: takes the per-sample table of
[`summarise_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_pepchem.md)
and reports, for each Condition and descriptor, the mean +/- sd **across
samples** of the chosen per-sample statistic. This is the
replicate-respecting summary
[`plot_property_sample_summary()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_property_sample_summary.md)
draws — its spread is between-sample variability, not between-peptide
spread.

## Usage

``` r
aggregate_pepchem(sample_summary, stat = c("Median", "Mean"))
```

## Arguments

- sample_summary:

  Output of
  [`summarise_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_pepchem.md)
  with `by = "Sample"`.

- stat:

  Per-sample statistic to aggregate: `"Median"` (default) or `"Mean"`.

## Value

A data frame with `Condition`, `Property`, `n_Samples`, `Mean`, `SD` and
`SEM`.

## Examples

``` r
if (FALSE) { # \dontrun{
aggregate_pepchem(summarise_pepchem(pepchem_by_sample(pep_short)))
} # }
```
