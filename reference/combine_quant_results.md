# Combine the quantitative and presence/absence tracks

Merges
[`test_differential()`](https://davidgz1.github.io/HowMaHiCo/reference/test_differential.md)
and
[`test_detection()`](https://davidgz1.github.io/HowMaHiCo/reference/test_detection.md)
into one table per contrast and assigns each feature a `Status`:
`up`/`down` when the moderated test passes both the FDR and the
fold-change cut-off, `exclusive_up`/ `exclusive_down` when the feature
is detected in `min_detect` units of one condition and in none of the
other, `ns` otherwise.

## Usage

``` r
combine_quant_results(
  diff_res,
  det_res,
  fdr = 0.05,
  log2fc = 1,
  min_detect = 2
)
```

## Arguments

- diff_res:

  Output of
  [`test_differential()`](https://davidgz1.github.io/HowMaHiCo/reference/test_differential.md).

- det_res:

  Output of
  [`test_detection()`](https://davidgz1.github.io/HowMaHiCo/reference/test_detection.md).

- fdr:

  Adjusted p-value cut-off for the quantitative test. Default `0.05`.

- log2fc:

  Absolute log2 fold-change cut-off. Default `1`.

- min_detect:

  Minimum number of units in which an exclusive feature must be detected
  in the condition where it is present (capped at that condition's
  number of units). Default `2`.

## Value

A data frame with the columns of both inputs plus `Status` (factor:
`up`, `down`, `exclusive_up`, `exclusive_down`, `ns`).

## Details

The exclusive flag is deliberately a **detection-count rule, not a
p-value cut-off**: with the small designs typical of immunopeptidomics
the Fisher exact test cannot reach a small p-value at all (a fully
exclusive feature in a 3-vs-3 comparison gives p = 0.1, and no
adjustment can improve on that), so gating the flag on the FDR would
silently hide every on/off ligand. The Fisher p-values from
[`test_detection()`](https://davidgz1.github.io/HowMaHiCo/reference/test_detection.md)
are carried along as supporting evidence and become decisive as the
number of replicates grows.

## Examples

``` r
if (FALSE) { # \dontrun{
results <- combine_quant_results(res, det, fdr = 0.05, log2fc = 1)
table(results$Contrast, results$Status)
} # }
```
