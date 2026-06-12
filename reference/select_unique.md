# Select distinct rows on a subset of columns

Shorthand for `select(...) |> unique() |> droplevels()` — used to build
the small per-comparison data frames consumed by
[`plot_upset_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_upset_batch.md)
and similar overlap helpers.

## Usage

``` r
select_unique(input, ...)
```

## Arguments

- input:

  A data frame.

- ...:

  Columns to select, forwarded to
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html)
  (tidy evaluation).

## Value

`input` restricted to the selected columns, with duplicate rows removed
and unused factor levels dropped.

## Examples

``` r
if (FALSE) { # \dontrun{
select_unique(pep_all, Condition, Sequence)
} # }
```
