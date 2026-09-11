# Rank the most prolific source proteins

The proteins contributing the most ligands (or the most intensity),
pooled across the whole table. In an immunopeptidome a small number of
source proteins usually dominate, and this is the table that shows
which.

## Usage

``` r
top_source_proteins(
  prot_all,
  n = 25,
  by = c("n_Peptides", "Area"),
  min_peptides = 1
)
```

## Arguments

- prot_all:

  Output of
  [`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md).

- n:

  Number of proteins to return. Default `25`.

- by:

  Ranking column: `"n_Peptides"` (default) or `"Area"`.

- min_peptides:

  Drop proteins contributing fewer ligands than this. Default `1`.

## Value

A data frame with one row per protein: `Protein`, `n_Peptides`,
`n_Sequences`, `n_Samples`, `Area`, ordered by `by` descending.

## Examples

``` r
if (FALSE) { # \dontrun{
top_source_proteins(build_prot_all(pep_short), n = 25)
} # }
```
