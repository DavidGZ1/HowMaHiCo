# Summarise peptide descriptors within a group

Collapses the per-peptide table of
[`pepchem_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/pepchem_by_sample.md)
to one row per (group, descriptor): the count, mean, median and sd over
that group's unique sequences. With the default `by = "Sample"` this is
the first of the two aggregation steps the report uses —
[`aggregate_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/aggregate_pepchem.md)
is the second.

## Usage

``` r
summarise_pepchem(props, by = "Sample", properties = NULL)
```

## Arguments

- props:

  Output of
  [`pepchem_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/pepchem_by_sample.md).

- by:

  Grouping column. Default `"Sample"`.

- properties:

  Descriptor columns to summarise. `NULL` (default) uses every numeric
  column that is not an annotation column.

## Value

A long data frame with the `by` column, `Condition` (when present),
`Property`, `N`, `Mean`, `Median` and `SD`.

## Examples

``` r
if (FALSE) { # \dontrun{
summarise_pepchem(pepchem_by_sample(pep_short))
} # }
```
