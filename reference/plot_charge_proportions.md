# Stacked bar chart of charge-state proportions by group

Plots the table produced by
[`get_proportion_charge()`](https://davidgz1.github.io/HowMaHiCo/reference/get_proportion_charge.md)
as a stacked proportion bar chart, with percentage labels.

## Usage

``` r
plot_charge_proportions(input, variable, label_size = 3)
```

## Arguments

- input:

  Output of
  [`get_proportion_charge()`](https://davidgz1.github.io/HowMaHiCo/reference/get_proportion_charge.md).

- variable:

  Grouping column for the x-axis (tidy-evaluated), e.g. `Condition`.

- label_size:

  Text size for the percentage labels (`geom_text`); mirrors the
  report's `PlotTextLabelSize` param.

## Value

A ggplot2 stacked bar chart.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_charge_proportions(get_proportion_charge(counts_charge_condition), Condition)
} # }
```
