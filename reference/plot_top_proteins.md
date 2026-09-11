# Ranked bar chart of the most prolific source proteins

Draws the
[`top_source_proteins()`](https://davidgz1.github.io/HowMaHiCo/reference/top_source_proteins.md)
table: which proteins contribute the most ligands (or the most
intensity) across the dataset.

## Usage

``` r
plot_top_proteins(top_tbl, by = c("n_Peptides", "Area"), title = NULL)
```

## Arguments

- top_tbl:

  Output of
  [`top_source_proteins()`](https://davidgz1.github.io/HowMaHiCo/reference/top_source_proteins.md).

- by:

  Column to plot: `"n_Peptides"` (default) or `"Area"`.

- title:

  Plot title. `NULL` (default) uses a generic one.

## Value

A ggplot object, or `NULL` when `top_tbl` has no rows.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_top_proteins(top_source_proteins(prot_all, n = 25))
} # }
```
