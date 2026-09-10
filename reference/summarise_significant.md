# Count significant features per contrast

Count significant features per contrast

## Usage

``` r
summarise_significant(results)
```

## Arguments

- results:

  Output of
  [`combine_quant_results()`](https://davidgz1.github.io/HowMaHiCo/reference/combine_quant_results.md).

## Value

A data frame with one row per contrast and one column per `Status`
level, plus `n_tested` (features with a quantitative p-value).

## Examples

``` r
if (FALSE) { # \dontrun{
summarise_significant(results)
} # }
```
