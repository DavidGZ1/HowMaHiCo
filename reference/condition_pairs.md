# All pairwise Condition comparisons

Replacement for the bare `combn(conditions, 2)` the report templates
used to call: [`utils::combn()`](https://rdrr.io/r/utils/combn.html)
errors with `n < m` when a subset happens to contain a single Condition,
which aborted the whole render. This returns an **empty list** in that
case, so the calling section can print a note and move on.

## Usage

``` r
condition_pairs(conditions, self = FALSE)
```

## Arguments

- conditions:

  Character vector or factor of condition names (factor levels are used,
  so the report's annotation order is preserved).

- self:

  Include the self-comparisons (`A vs A`) appended after the pairs, as
  the overlap-matrix sections need. Default `FALSE`.

## Value

A list of length-2 character vectors, named `"<Cond1>_vs_<Cond2>"`;
empty (and, with `self = TRUE`, self-comparisons only) when fewer than
two conditions are present.

## Examples

``` r
condition_pairs(c("CTRL", "TREAT", "OTHER"))
#> $CTRL_vs_TREAT
#> [1] "CTRL"  "TREAT"
#> 
#> $CTRL_vs_OTHER
#> [1] "CTRL"  "OTHER"
#> 
#> $TREAT_vs_OTHER
#> [1] "TREAT" "OTHER"
#> 
condition_pairs("CTRL")                 # empty list, no error
#> list()
condition_pairs("CTRL", self = TRUE)    # just CTRL vs CTRL
#> $CTRL_vs_CTRL
#> [1] "CTRL" "CTRL"
#> 
```
