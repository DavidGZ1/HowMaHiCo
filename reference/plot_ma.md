# MA plot of a differential-abundance result

Fold change against average abundance — the diagnostic that shows
whether the fold changes are intensity-dependent, i.e. whether the
normalization did its job.

## Usage

``` r
plot_ma(results, log2fc = 1, title = NULL)
```

## Arguments

- results:

  Output of
  [`combine_quant_results()`](https://davidgz1.github.io/HowMaHiCo/reference/combine_quant_results.md)
  (one or several contrasts).

- log2fc:

  Absolute fold-change cut-off drawn as horizontal lines. Default `1`.

- title:

  Plot title. Default `NULL` (the contrast name).

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_ma(subset(results, Contrast == "TREAT_vs_CTRL"))
} # }
```
