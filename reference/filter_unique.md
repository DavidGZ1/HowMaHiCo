# Filter rows and drop to distinct/unused-level state

Shorthand for `filter(...) %>% unique() %>% droplevels()` — the
filtering counterpart to
[`select_unique()`](https://davidgz1.github.io/HowMaHiCo/reference/select_unique.md),
used to restrict a `pep_all`-shaped data frame to one
`Condition`/`Sample_type`/... before batch-plotting its overlap.

## Usage

``` r
filter_unique(input, ...)
```

## Arguments

- input:

  A data frame.

- ...:

  Filtering conditions, forwarded to
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
  (tidy evaluation).

## Value

`input` restricted to the matching rows, with duplicate rows removed and
unused factor levels dropped.

## Examples

``` r
if (FALSE) { # \dontrun{
filter_unique(pep_all, Condition == "JY")
} # }
```
