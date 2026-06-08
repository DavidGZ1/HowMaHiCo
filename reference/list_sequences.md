# List unique peptide sequences per group

List unique peptide sequences per group

## Usage

``` r
list_sequences(input, by)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with a `Sequence` column.

- by:

  Column name (string) to split by, e.g. `"Condition"`.

## Value

A named list of character vectors, one per level of `by`, each
containing that group's unique non-empty sequences.

## Examples

``` r
if (FALSE) { # \dontrun{
list_sequences(pep_all, "Condition")
} # }
```
