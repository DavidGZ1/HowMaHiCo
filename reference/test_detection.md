# Presence/absence test between conditions (Fisher exact)

Complements
[`test_differential()`](https://davidgz1.github.io/HowMaHiCo/reference/test_differential.md)
for the features a quantitative test cannot rank: those detected in one
condition and (nearly) absent from the other, which in immunopeptidomics
are often the biologically interesting ligands. For every feature and
contrast a Fisher exact test is run on the 2x2 table of detected /
not-detected units, with Benjamini–Hochberg adjustment within the
contrast. Their fold change is undefined by construction — imputing one
would make it an artefact of the imputation width — so detection
frequency, not intensity, is what is tested.

## Usage

``` r
test_detection(mat, coldata, contrasts = NULL)
```

## Arguments

- mat:

  Numeric matrix (before or after imputation; detection is taken from
  the `imputed` attribute when present, otherwise from `!is.na(mat)`).

- coldata:

  Column metadata from
  [`build_quant_matrix()`](https://davidgz1.github.io/HowMaHiCo/reference/build_quant_matrix.md).

- contrasts:

  List of length-2 character vectors, or `NULL` (default) for all
  pairwise comparisons.

## Value

A data frame with `Contrast`, `Feature`, `n_det_ref`, `n_tot_ref`,
`n_det_test`, `n_tot_test`, `P.Value_det`, `adj.P.Val_det` and
`Exclusive_in` (the condition name when the feature is detected in one
condition only, `NA` otherwise).

## Examples

``` r
if (FALSE) { # \dontrun{
det <- test_detection(qm$mat, qm$coldata)
subset(det, !is.na(Exclusive_in) & adj.P.Val_det < 0.05)
} # }
```
