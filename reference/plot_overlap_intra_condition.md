# Stacked overlap barplot (all vs short peptides) for one ID level

Builds two barplots — one for `pep_all` and one for `pep_short` —
showing how many IDs were detected in 1, 2, 3, … replicates per
Condition, then combines them vertically with
[`ggpubr::ggarrange()`](https://rpkgs.datanovia.com/ggpubr/reference/ggarrange.html).
Works for Peptides, Sequences, or Proteins by dispatching on `id_col`.

## Usage

``` r
plot_overlap_intra_condition(
  pep_all,
  pep_short,
  id_col,
  shortpep_range = c(8, 13)
)
```

## Arguments

- pep_all, pep_short:

  `pep_all`-shaped data frames (all and length- filtered peptides
  respectively).

- id_col:

  Column defining the ID level: `"Peptide"`, `"Sequence"`, or
  `"Accession"`.

- shortpep_range:

  Length-2 numeric vector `c(min, max)` used only to build the subtitle
  of the lower panel.

## Value

A
[`ggpubr::ggarrange()`](https://rpkgs.datanovia.com/ggpubr/reference/ggarrange.html)
figure (upper: all peptides; lower: short peptides) with a shared
legend.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_overlap_intra_condition(pep_all, pep_short, "Peptide")
plot_overlap_intra_condition(pep_all, pep_short, "Accession")
} # }
```
