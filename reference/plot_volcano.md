# Volcano plot of a differential-abundance result

Standard volcano (log2 fold change against -log10 adjusted p-value) of
one contrast, with the condition-exclusive features from the
presence/absence track drawn as triangles at the plot margin: their fold
change is undefined, so they cannot sit on the x axis, but they are
usually the most interesting hits in an immunopeptidomics comparison and
must stay visible.

## Usage

``` r
plot_volcano(results, fdr = 0.05, log2fc = 1, title = NULL)
```

## Arguments

- results:

  Output of
  [`combine_quant_results()`](https://davidgz1.github.io/HowMaHiCo/reference/combine_quant_results.md),
  filtered to a single contrast (or containing several, in which case
  the plot is facetted).

- fdr:

  Adjusted p-value cut-off drawn as a horizontal line. Default `0.05`.

- log2fc:

  Absolute fold-change cut-off drawn as vertical lines. Default `1`.

- title:

  Plot title. Default `NULL` (the contrast name).

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_volcano(subset(results, Contrast == "TREAT_vs_CTRL"))
} # }
```
