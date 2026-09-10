# Significant-feature counts per contrast

Bar chart of the
[`summarise_significant()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_significant.md)
table: how many features change in each direction, and how many are
condition-exclusive, per comparison.

## Usage

``` r
plot_sig_summary(summary_df)
```

## Arguments

- summary_df:

  Output of
  [`summarise_significant()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_significant.md).

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_sig_summary(summarise_significant(results))
} # }
```
