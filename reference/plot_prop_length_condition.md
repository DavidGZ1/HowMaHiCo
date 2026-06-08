# Stacked bar chart of peptide proportions by `Length_range` and `Condition`

Plots the table produced by
[`count_ids_condition_bylengthrange()`](https://davidgz1.github.io/HowMaHiCo/reference/count_ids_condition_bylengthrange.md)
as a stacked proportion bar chart per condition, with percentage labels.

## Usage

``` r
plot_prop_length_condition(input, level2plot = "Peptides", label_size = 1.6)
```

## Arguments

- input:

  Output of
  [`count_ids_condition_bylengthrange()`](https://davidgz1.github.io/HowMaHiCo/reference/count_ids_condition_bylengthrange.md).

- level2plot:

  Which `Level` to plot — one of `"Peptides.Modified"`, `"Peptides"`,
  `"Proteins"`.

- label_size:

  Text size for the percentage labels (`geom_text`); mirrors the
  report's `PlotTextLabelSize` param.

## Value

A ggplot2 stacked bar chart.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_prop_length_condition(count_ids_condition_bylengthrange(pep_all))
} # }
```
