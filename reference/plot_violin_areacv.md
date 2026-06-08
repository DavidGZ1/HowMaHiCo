# Violin + boxplot of Area %CV by group

Plots the table produced by
[`summarise_area()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_area.md)
as violin/boxplot pairs per group, with a dashed reference line at 20%
CV and an "n = ..." label annotating each group's peptide count.

## Usage

``` r
plot_violin_areacv(input, by, label_size = 1.6)
```

## Arguments

- input:

  Output of
  [`summarise_area()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_area.md).

- by:

  Grouping column for the x-axis (tidy-evaluated), e.g. `Condition`.

- label_size:

  Text size for the "n = ..." annotation (`stat_summary`); mirrors the
  report's `PlotTextLabelSize` param.

## Value

A ggplot2 violin/boxplot figure.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_violin_areacv(summarise_area(pep_all, Condition), Condition)
} # }
```
