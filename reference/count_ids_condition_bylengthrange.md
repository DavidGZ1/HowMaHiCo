# ID counts and proportions by `Length_range` and `Condition`

Computes peptide/sequence/protein counts for each `Condition` ×
`Length_range` combination (plus an `"All peptides"` total row per
`Condition`), pivots to long format, and derives the proportion,
percentage, and cumulative proportion/count of each `Length_range` class
relative to its condition's total — the table consumed by
[`plot_prop_length_condition()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_prop_length_condition.md).

## Usage

``` r
count_ids_condition_bylengthrange(input, group_var = "Condition")
```

## Arguments

- input:

  A `pep_all`-shaped data frame with `Condition` (or the column named by
  `group_var`), `Length_range`, `Peptide`, `Sequence`, `Accession`
  columns.

- group_var:

  Name of the grouping column. Default `"Condition"`; pass `"Sample"` to
  compute per-sample proportions.

## Value

A long-format data frame of counts/proportions/percentages per
`group_var` × `Length_range` × `Level` (`Peptides.Modified`/`Peptides`/
`Proteins`), with `Length_range` factor-ordered for stacked-bar
plotting. The grouping column retains the name supplied in `group_var`.

## Details

Defines its own internal `count_ids(input, ..., total = FALSE)` helper
(grouping on arbitrary `...` columns, with an optional synthetic
`"Total"` row) — note this **shadows** the package's simpler
[`count_ids()`](https://davidgz1.github.io/HowMaHiCo/reference/count_ids.md)
for the duration of this function only; the two serve different call
patterns and were kept distinct rather than unified, to stay faithful to
the original "imported from functions_thunder" implementation.

## Examples

``` r
if (FALSE) { # \dontrun{
count_ids_condition_bylengthrange(pep_all)
count_ids_condition_bylengthrange(pep_all, group_var = "Sample")
} # }
```
