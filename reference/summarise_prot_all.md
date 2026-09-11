# Condense the protein table across samples

Collapses
[`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md)
to one row per (protein, group): in how many samples of that group the
protein was seen, the mean +/- sd number of ligands it contributed, and
the total intensity.

## Usage

``` r
summarise_prot_all(prot_all, by = "Condition")
```

## Arguments

- prot_all:

  Output of
  [`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md).

- by:

  Grouping column. Default `"Condition"`.

## Value

A data frame with `Protein`, the `by` column, `n_Samples_detected`,
`n_Peptides_mean`, `n_Peptides_sd`, `n_Peptides_total` and `Area_total`.

## Examples

``` r
if (FALSE) { # \dontrun{
summarise_prot_all(build_prot_all(pep_short))
} # }
```
