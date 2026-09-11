# How widely each source protein is detected

Counts source proteins by the number of samples — and, when available,
Conditions — they were identified in. The left-hand end of this
distribution is the one-sample-only tail, which at protein level is
usually driven by single-ligand identifications rather than by biology.

## Usage

``` r
plot_protein_detection(prot_all, by = c("Sample", "Condition"), title = NULL)
```

## Arguments

- prot_all:

  Output of
  [`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md).

- by:

  `"Sample"` (default) or `"Condition"`.

- title:

  Plot title. `NULL` (default) uses a generic one.

## Value

A ggplot object, or `NULL` when `prot_all` has no rows.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_protein_detection(build_prot_all(pep_short))
} # }
```
