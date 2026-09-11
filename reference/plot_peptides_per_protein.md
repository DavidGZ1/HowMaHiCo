# Distribution of ligands per source protein

How many peptides each source protein contributes. In an immunopeptidome
this distribution is strongly skewed — most proteins yield a single
ligand and a small number yield many — so it is the shape, not the mean,
that carries the information.

## Usage

``` r
plot_peptides_per_protein(
  prot_all,
  type = c("histogram", "violin"),
  title = NULL
)
```

## Arguments

- prot_all:

  Output of
  [`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md).

- type:

  `"histogram"` (default) or `"violin"`.

- title:

  Plot title. `NULL` (default) uses a generic one.

## Value

A ggplot object, or `NULL` when `prot_all` has no rows.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_peptides_per_protein(build_prot_all(pep_short))
} # }
```
