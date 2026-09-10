# P-value histogram (test calibration diagnostic)

Histogram of the raw p-values of one contrast. A well-behaved test gives
a uniform histogram with a spike near zero; a hump towards 1, or a wave,
means the model assumptions are violated (wrong design, unaccounted
batch, over- aggressive imputation) and the FDR is not trustworthy.

## Usage

``` r
plot_pvalue_hist(results, title = NULL)
```

## Arguments

- results:

  Output of
  [`test_differential()`](https://davidgz1.github.io/HowMaHiCo/reference/test_differential.md)
  or
  [`combine_quant_results()`](https://davidgz1.github.io/HowMaHiCo/reference/combine_quant_results.md).

- title:

  Plot title. Default `NULL` (the contrast name).

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_pvalue_hist(subset(results, Contrast == "TREAT_vs_CTRL"))
} # }
```
