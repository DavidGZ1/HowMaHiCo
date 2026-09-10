# Per-Condition mean +/- sd of a descriptor across samples

Draws the
[`aggregate_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/aggregate_pepchem.md)
table for one descriptor: each point is a sample's median, the bar and
error bar are the mean +/- sd **across samples**. This is the
replicate-respecting summary — the error bar answers "how reproducible
is this Condition", which a per-peptide distribution cannot.

## Usage

``` r
plot_property_sample_summary(summ, var, points = NULL, title = NULL)
```

## Arguments

- summ:

  Output of
  [`aggregate_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/aggregate_pepchem.md).

- var:

  Descriptor to draw (a value of the `Property` column).

- points:

  Optional per-sample table from
  [`summarise_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_pepchem.md),
  overlaid as jittered points. Default `NULL`.

- title:

  Plot title. `NULL` (default) uses `var`.

## Value

A ggplot object, or `NULL` when the descriptor is absent.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_property_sample_summary(aggregate_pepchem(sample_summary), "GRAVY")
} # }
```
