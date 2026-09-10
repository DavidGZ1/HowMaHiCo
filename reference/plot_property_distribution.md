# Distribution of one peptide descriptor across Conditions

Per-peptide distribution of a single descriptor, coloured by Condition.
This is the *repertoire* view: every unique sequence of a Condition
contributes one value, so the spread is between-peptide, not
between-replicate — read
[`plot_property_sample_summary()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_property_sample_summary.md)
alongside it for the replicate view.

## Usage

``` r
plot_property_distribution(
  props,
  var,
  type = c("density", "violin"),
  title = NULL
)
```

## Arguments

- props:

  Output of
  [`pepchem_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/pepchem_by_sample.md).

- var:

  Name (string) of the descriptor column to draw.

- type:

  `"density"` (default) or `"violin"`.

- title:

  Plot title. `NULL` (default) uses `var`.

## Value

A ggplot object, or `NULL` when the column is absent or all missing.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_property_distribution(props, "GRAVY")
} # }
```
