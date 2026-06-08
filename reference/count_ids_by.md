# Wide table of peptide identifications by an arbitrary grouping

Counts the number of distinct samples in which each peptide was
identified, grouped by `...` plus the standard identity columns, then
pivots to one column per `Condition` (`n_Samples.<Condition>`).

## Usage

``` r
count_ids_by(input, ...)
```

## Arguments

- input:

  A `pep_all`-shaped data frame.

- ...:

  Additional grouping variable(s) (besides `Condition`, `Accession`,
  `ProteinFirst`, `GeneFirst`, `Length`, `Peptide`, `Sequence`),
  forwarded to
  [`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html).

## Value

A wide data frame, one row per peptide, with `n_Samples.<Condition>`
columns giving the number of samples it was seen in for each condition.

## Examples

``` r
if (FALSE) { # \dontrun{
count_ids_by(pep_all, BioReplicate)
} # }
```
