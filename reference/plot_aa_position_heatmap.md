# Per-position amino-acid frequency heatmap

Tile map of the
[`aa_position_frequency()`](https://davidgz1.github.io/HowMaHiCo/reference/aa_position_frequency.md)
table: position on the x axis, residue on the y axis, one facet per
group. This is the numeric complement to the sequence logos in the
`01_id_counts` report — a logo scales letters by information content and
so hides which residue a flat position prefers, while the heatmap keeps
every frequency readable and comparable across Conditions.

## Usage

``` r
plot_aa_position_heatmap(freq, ncol = 3, title = NULL)
```

## Arguments

- freq:

  Output of
  [`aa_position_frequency()`](https://davidgz1.github.io/HowMaHiCo/reference/aa_position_frequency.md).

- ncol:

  Facet columns. Default `3`.

- title:

  Plot title. `NULL` (default) builds one from the peptide length
  recorded on `freq`.

## Value

A ggplot object, or `NULL` when `freq` has no rows.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_aa_position_heatmap(aa_position_frequency(pep_short$Sequence,
                                               groups = pep_short$Condition))
} # }
```
