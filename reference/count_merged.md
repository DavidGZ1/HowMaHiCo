# Count distinct elements across the union of two conditions

Counterpart to
[`count_intersect()`](https://davidgz1.github.io/HowMaHiCo/reference/count_intersect.md)
— used together to derive the overlap/total ratio for a pair of
conditions.

## Usage

``` r
count_merged(input, variable, cond1, cond2)
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

The number of distinct `variable` values present in `cond1` and/or
`cond2` combined.

## Examples

``` r
if (FALSE) { # \dontrun{
count_merged(pep_all, variable = "Peptide", cond1 = "JY", cond2 = "Plasma")
} # }
```
