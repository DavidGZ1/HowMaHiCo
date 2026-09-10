# Amino-acid composition across groups

Draws the
[`aa_composition()`](https://davidgz1.github.io/HowMaHiCo/reference/aa_composition.md)
table three ways. `"bar"` and `"heatmap"` show the residue frequency
itself; `"enrichment"` shows log2 of each group's frequency over the
pooled frequency of the whole table, which puts every residue on a
common, centred axis and makes a compositional shift between Conditions
visible without an external proteome background.

## Usage

``` r
plot_aa_composition(
  comp,
  type = c("bar", "heatmap", "enrichment"),
  title = NULL
)
```

## Arguments

- comp:

  Output of
  [`aa_composition()`](https://davidgz1.github.io/HowMaHiCo/reference/aa_composition.md)
  (needs `Frequency`).

- type:

  `"bar"` (default), `"heatmap"` or `"enrichment"`.

- title:

  Plot title. `NULL` (default) picks one from `type`.

## Value

A ggplot object, or `NULL` when `comp` has no rows.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_aa_composition(aa_composition(pep_short$Sequence, pep_short$Condition))
} # }
```
