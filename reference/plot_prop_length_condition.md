# Stacked bar chart of peptide proportions by `Length_range` and `Condition`

Plots the table produced by
[`count_ids_condition_bylengthrange()`](https://davidgz1.github.io/HowMaHiCo/reference/count_ids_condition_bylengthrange.md)
as a stacked proportion bar chart per condition, with percentage labels.

## Usage

``` r
plot_prop_length_condition(
  input,
  level2plot = "Peptides",
  label_size = 1.6,
  palette = NULL,
  x_var = "Condition"
)
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

- palette:

  Optional named character vector mapping `Length_range` values to fill
  colours. When `NULL` (default) `scale_fill_viridis_d()` is used.

- x_var:

  Name of the column to map to the x-axis. Default `"Condition"`; pass
  `"Sample"` for the sample-level proportion plot.

## Value

A ggplot2 stacked bar chart.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_prop_length_condition(count_ids_condition_bylengthrange(pep_all))
plot_prop_length_condition(count_ids_condition_bylengthrange(pep_all, "Sample"),
                           x_var = "Sample")
} # }
```
