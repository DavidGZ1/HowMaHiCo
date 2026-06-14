# Overlap barplot for one ID level

Builds a barplot showing how many IDs were detected in 1, 2, 3, …
replicates per Condition, for a single `pep_all`-shaped data frame.
Works for Peptides, Sequences, or Proteins by dispatching on `id_col`.
Call it once per length subset (e.g. all peptides, then length-selected
peptides) to get an individual plot for each.

## Usage

``` r
plot_overlap_intra_condition(
  df,
  id_col,
  title = NULL,
  shortpep_range = c(8, 13)
)
```

## Arguments

- df:

  A `pep_all`-shaped data frame (e.g. `pep_all`, or the length-filtered
  `pep_short`).

- id_col:

  Column defining the ID level: `"Peptide"`, `"Sequence"`, or
  `"Accession"`.

- title:

  Plot title. When `NULL` (default), a generic id-based label
  (`"Nb Peptides"` etc.) is used.

- shortpep_range:

  Length-2 numeric vector `c(min, max)`; retained for API compatibility
  (no longer used to build a subtitle now that all/short are plotted
  separately).

## Value

A ggplot2 barplot of IDs by number of replicates, per Condition.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_overlap_intra_condition(pep_all, "Peptide", title = "All Peptides")
plot_overlap_intra_condition(pep_short, "Accession")
} # }
```
