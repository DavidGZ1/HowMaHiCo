# Default quality-score thresholds and weights

The literature-informed default scoring table used by
[`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md)
when no QC-relative calibration is requested. One row per metric, giving
the green (full-marks) and amber (half-marks) thresholds, the scoring
`direction`, the composite `weight`, and a human-readable `label`. Edit
or pass a modified copy to override. Metrics whose absolute thresholds
are `NA` (the depth metrics) are scored only in QC-relative mode (see
[`calibrate_thresholds_from_qc()`](https://davidgz1.github.io/HowMaHiCo/reference/calibrate_thresholds_from_qc.md)).

## Usage

``` r
quality_thresholds_default(mhcclass = "MHC1")
```

## Arguments

- mhcclass:

  MHC class the thresholds are for. `"MHC1_mouse"` relabels the
  `frac_9mer` row to "8/9-mer fraction" and raises its green/amber
  cut-offs, because that metric counts two canonical lengths for murine
  H-2.

## Value

A data frame with columns `metric`, `label`, `direction`
(`"higher_better"`/`"lower_better"`), `green`, `amber`, `weight`.

## Examples

``` r
quality_thresholds_default()
#>                    metric                              label     direction
#> 1          frac_in_window                   Length in window higher_better
#> 2               frac_9mer                     9-mer fraction higher_better
#> 3  frac_cterm_KR_longonly Tryptic background (long peptides)  lower_better
#> 4           frac_cterm_KR        C-terminal K/R (diagnostic)  lower_better
#> 5      anchor_information               Anchor motif clarity higher_better
#> 6        frac_cross_class          Cross-class contamination  lower_better
#> 7         frac_charge_1_2                       Charge 1+/2+ higher_better
#> 8            n_unique_pep                    Unique peptides higher_better
#> 9  n_unique_pep_in_window          Unique peptides in window higher_better
#> 10      n_source_proteins                    Source proteins higher_better
#> 11         median_abs_ppm                       Median |ppm|  lower_better
#>    green amber weight
#> 1   0.80  0.60    3.0
#> 2   0.35  0.20    1.5
#> 3   0.30  0.50    1.0
#> 4   0.30  0.50    0.0
#> 5   2.00  1.00    3.0
#> 6   0.05  0.15    0.5
#> 7   0.85  0.70    1.5
#> 8     NA    NA    0.5
#> 9     NA    NA    0.5
#> 10    NA    NA    0.5
#> 11  5.00 10.00    1.0
quality_thresholds_default("MHC1_mouse")
#>                    metric                              label     direction
#> 1          frac_in_window                   Length in window higher_better
#> 2               frac_9mer                   8/9-mer fraction higher_better
#> 3  frac_cterm_KR_longonly Tryptic background (long peptides)  lower_better
#> 4           frac_cterm_KR        C-terminal K/R (diagnostic)  lower_better
#> 5      anchor_information               Anchor motif clarity higher_better
#> 6        frac_cross_class          Cross-class contamination  lower_better
#> 7         frac_charge_1_2                       Charge 1+/2+ higher_better
#> 8            n_unique_pep                    Unique peptides higher_better
#> 9  n_unique_pep_in_window          Unique peptides in window higher_better
#> 10      n_source_proteins                    Source proteins higher_better
#> 11         median_abs_ppm                       Median |ppm|  lower_better
#>    green amber weight
#> 1   0.80  0.60    3.0
#> 2   0.50  0.30    1.5
#> 3   0.30  0.50    1.0
#> 4   0.30  0.50    0.0
#> 5   2.00  1.00    3.0
#> 6   0.05  0.15    0.5
#> 7   0.85  0.70    1.5
#> 8     NA    NA    0.5
#> 9     NA    NA    0.5
#> 10    NA    NA    0.5
#> 11  5.00 10.00    1.0
```
