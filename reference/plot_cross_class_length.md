# Per-sample peptide-length histogram highlighting cross-class contamination

Faceted (by `Sample`) count histogram of distinct-peptide lengths, with
each length bar coloured by region: the current class's expected window,
the **cross-class** region (the other MHC class's length range falling
outside the current window — i.e. MHC-II ligands contaminating an MHC-I
pulldown, or vice versa), and everything else. Visualises the
`frac_cross_class` metric of
[`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md).
For a custom length window (MHCclass neither `"MHC1"` nor `"MHC2"`) the
cross-class region is undefined and an informative empty plot is
returned.

## Usage

``` r
plot_cross_class_length(pep_all, shortpep_range = c(8, 13), mhcclass = "MHC1")
```

## Arguments

- pep_all:

  A unified `pep_all` data frame with `Sample`, `Peptide`, `Length`.

- shortpep_range:

  Length-2 numeric `c(min, max)` — the current class's expected
  ligand-length window.

- mhcclass:

  `"MHC1"` or `"MHC2"`.

## Value

A ggplot2 faceted histogram.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_cross_class_length(pep_all, shortpep_range = c(8, 13), mhcclass = "MHC1")
} # }
```
