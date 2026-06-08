# Per-peptide Area mean/sd/%CV summary by group

Per-peptide Area mean/sd/%CV summary by group

## Usage

``` r
summarise_area(input, by)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with `Accession`, `Peptide`, `Charge`,
  `Area` columns.

- by:

  Additional grouping variable (e.g. `Condition`, `BioReplicate`), used
  with tidy evaluation.

## Value

A data frame with one row per `Accession`/`Peptide`/`Charge`/`by` group
and columns `Count`, `Area_mean`, `Area_sd`, `Area_CV`, `Area_CV_perc`.

## Examples

``` r
if (FALSE) { # \dontrun{
summarise_area(pep_all, Condition)
} # }
```
