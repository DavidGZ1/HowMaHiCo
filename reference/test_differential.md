# Differential abundance between conditions

Fits a linear model per feature and tests every requested condition
pair. With `method = "limma"` (default) the model is `~ 0 + Condition`
with pairwise contrasts and empirical-Bayes moderation
([`limma::eBayes()`](https://rdrr.io/pkg/limma/man/ebayes.html),
`trend = TRUE`, `robust = TRUE`): with the 3–5 replicates typical of an
immunopeptidomics experiment the per-feature variance estimate is
extremely noisy, and shrinking it towards a mean-variance trend fitted
across all features increases power and controls the FDR better than
per-feature t-tests (Smyth 2004; Kammers et al. 2015). `trend = TRUE`
accounts for the pronounced intensity-dependent variance of label-free
MS, `robust = TRUE` keeps a few wildly variable features from inflating
the prior variance (Phipson et al. 2016). limma fits each row on its
observed values, so the matrix may (and by default does) contain `NA`s.

## Usage

``` r
test_differential(
  mat,
  coldata,
  contrasts = NULL,
  method = c("limma", "ttest"),
  block = NULL,
  trend = TRUE,
  robust = TRUE,
  min_obs = 2
)
```

## Arguments

- mat:

  Numeric matrix of (normalized) log2 intensities.

- coldata:

  Column metadata from
  [`build_quant_matrix()`](https://davidgz1.github.io/HowMaHiCo/reference/build_quant_matrix.md)
  (`Unit`, `Condition`, `BioReplicate`).

- contrasts:

  List of length-2 character vectors `c(reference, test)`, as produced
  by [`utils::combn()`](https://rdrr.io/r/utils/combn.html) on the
  condition levels. `NULL` (default) uses all pairwise comparisons in
  factor order.

- method:

  `"limma"` (default) or `"ttest"`.

- block:

  Optional blocking variable (name of a `coldata` column, or a vector of
  length `ncol(mat)`) passed to
  [`limma::duplicateCorrelation()`](https://rdrr.io/pkg/limma/man/dupcor.html)
  — e.g. `"BioReplicate"` when the columns are individual runs, or a
  patient identifier in a paired design. Ignored by `method = "ttest"`.

- trend, robust:

  Passed to
  [`limma::eBayes()`](https://rdrr.io/pkg/limma/man/ebayes.html).
  Defaults `TRUE`.

- min_obs:

  Minimum quantified values required *per group* for a feature to be
  tested by `method = "ttest"`. Default `2`.

## Value

A data frame with one row per feature and contrast: `Contrast`,
`Feature`, `logFC` (positive = higher in the test condition), `AveExpr`,
`t`, `P.Value`, `adj.P.Val` (BH within contrast), `B` (limma only),
`n_obs_ref`, `n_obs_test`. For `method = "limma"` the fitted `MArrayLM`
object is attached as the attribute `fit` (used for the mean-variance
diagnostic plot).

## Details

`method = "ttest"` runs an ordinary Welch t-test per feature and
contrast with Benjamini–Hochberg adjustment — a dependency-free fallback
and a useful sanity check against the moderated result.

## Examples

``` r
if (FALSE) { # \dontrun{
res <- test_differential(mat_n, qm$coldata, method = "limma")
head(res[order(res$adj.P.Val), ])
} # }
```
