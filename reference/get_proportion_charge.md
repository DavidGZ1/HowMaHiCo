# Proportions of each charge group within a count table

Pivots a wide `n_*` count table to long format and computes, within each
`Condition` × `Level` group, the proportion/percentage/cumulative
proportion of each `Charge_group` relative to its `"Total"` row — the
table consumed by
[`plot_charge_proportions()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_charge_proportions.md).

## Usage

``` r
get_proportion_charge(df)
```

## Arguments

- df:

  A count data frame with `Condition`, `Charge_group`, and one or more
  `n_*`-prefixed count columns, including a `"Total"` `Charge_group` row
  per `Condition`.

## Value

`df` reshaped to long format with added `Level`, `Count`, `Proportion`,
`Percentage`, `CumProportion` columns.

## Examples

``` r
if (FALSE) { # \dontrun{
get_proportion_charge(counts_charge_condition)
} # }
```
