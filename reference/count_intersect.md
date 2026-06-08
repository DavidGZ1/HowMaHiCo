# Count distinct elements shared between two conditions

Count distinct elements shared between two conditions

## Usage

``` r
count_intersect(input, variable, cond1, cond2)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with `Condition` and `variable` columns.

- variable:

  Name (string) of the column whose distinct values are compared, e.g.
  `"Peptide"`.

- cond1, cond2:

  The two `Condition` levels to compare.

## Value

The number of distinct `variable` values present in both `cond1` and
`cond2`.

## Examples

``` r
if (FALSE) { # \dontrun{
count_intersect(pep_all, variable = "Peptide", cond1 = "JY", cond2 = "Plasma")
} # }
```
