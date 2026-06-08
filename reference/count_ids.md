# Count distinct peptides, sequences, and proteins

Count distinct peptides, sequences, and proteins

## Usage

``` r
count_ids(input)
```

## Arguments

- input:

  A `pep_all`-shaped data frame (or any grouped subset of one) with
  `Peptide`/`Sequence`/`Accession` columns.

## Value

A one-row (or one-row-per-group, if `input` is grouped) data frame with
`n_Peptides`, `n_Sequences`, `n_Proteins`.

## Examples

``` r
if (FALSE) { # \dontrun{
count_ids(pep_all)
} # }
```
