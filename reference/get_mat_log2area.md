# Build a `Log2Area` matrix for clustering/heatmaps/correlation

Pivots `input` to a wide `row` × `col` matrix of (mean, if needed)
`Log2Area` values, dropping rows that are entirely `NA` ("phantom IDs")
and ordering columns by the factor levels of `col`.

## Usage

``` r
get_mat_log2area(input, row, col)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with `Log2Area` and the columns named by
  `row`/`col`.

- row:

  Column to use for matrix rows (tidy-evaluated; usually `PeptideID` or
  `ProteinFirst`).

- col:

  Column to use for matrix columns (tidy-evaluated; must be a factor —
  its levels set the column order, e.g. `Sample` or `Condition`). When
  several rows share the same `col` value, their `Log2Area` values are
  averaged (`na.rm = TRUE`).

## Value

A numeric matrix with `NA`s preserved, rows named by `row` and columns
ordered by the factor levels of `col`.

## Examples

``` r
if (FALSE) { # \dontrun{
get_mat_log2area(pep_all, PeptideID, Sample)
} # }
```
