# Per-sample composite quality-score bar chart

Plots the `composite_score` of a
[`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md)
table as a bar per sample, coloured by traffic-light `category`
(Pass/Warning/Fail), with dashed reference lines at the 70 (Pass) and 40
(Warning) cut-offs. QC samples are marked with a trailing asterisk.

## Usage

``` r
plot_quality_composite(scores)
```

## Arguments

- scores:

  Output of
  [`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md).

## Value

A ggplot2 bar chart.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_quality_composite(score_sample_quality(pep_all, c(8, 13), "MHC1"))
} # }
```
