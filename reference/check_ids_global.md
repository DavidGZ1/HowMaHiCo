# Total ID counts split by protein/decoy/contaminant assignment

Classifies every row as `"Decoy"`, `"Contaminant"`, `"Not Assigned"`, or
`"Assigned to Protein"` (based on `ProteinFirst`/`Accession`), counts
IDs within each class plus an overall `"Total"` row, and adds the
proportion of the total each class represents.

## Usage

``` r
check_ids_global(input)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with `ProteinFirst`, `Accession`,
  `Peptide`, `Sequence` columns.

## Value

A data frame with one row per `ProteinType` (plus `"Total"`) and columns
`n_Peptides`/`n_Sequences`/`n_Proteins` and their `prop_*` proportions
of the total.

## Examples

``` r
if (FALSE) { # \dontrun{
check_ids_global(pep_all)
} # }
```
