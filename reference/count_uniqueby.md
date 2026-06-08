# Count distinct entries in one or more variables, grouped by other variables

Count distinct entries in one or more variables, grouped by other
variables

## Usage

``` r
count_uniqueby(df, vars, by, total = FALSE, sep = "_")
```

## Arguments

- df:

  A data frame.

- vars:

  Column(s) (tidy-evaluated) whose distinct entries are counted, e.g.
  `Sample` or `c(Sample, Patient)`.

- by:

  Column(s) (tidy-evaluated) to group by.

- total:

  Logical; if `TRUE`, an extra set of rows is appended with every `by`
  column collapsed to `"Total"`, giving an overall count alongside the
  per-group ones.

- sep:

  Separator used when building the output column names
  (`"<fn><sep><col>"`, e.g. `"n_Sample"`).

## Value

A data frame with one row per `by`-group (plus, if `total = TRUE`, one
`"Total"` row) and `n_<vars>`-named columns of distinct counts.

## Examples

``` r
if (FALSE) { # \dontrun{
count_uniqueby(pep_all, vars = Sample, by = Condition, total = TRUE)
} # }
```
