# Left-censored imputation of missing quantitative values

Mass-spectrometry missingness is a mixture of MNAR (below the limit of
detection) and MAR/stochastic values; in immunopeptidomics a large share
is neither, but genuine biology (a ligand presented in one condition
only). This function implements the two left-censored conventions used
in the field, and the default is to impute nothing — the
presence/absence track
([`test_detection()`](https://davidgz1.github.io/HowMaHiCo/reference/test_detection.md))
handles the exclusive features instead of inventing an intensity for
them.

## Usage

``` r
impute_quant(
  mat,
  method = c("none", "minprob", "mindet"),
  shift = 1.8,
  width = 0.3,
  q = 0.01,
  seed = 1234
)
```

## Arguments

- mat:

  Numeric matrix of log2 intensities.

- method:

  `"none"` (default), `"minprob"` (per-sample down-shifted normal draw,
  the Perseus convention) or `"mindet"` (deterministic per-sample low
  quantile).

- shift:

  Down-shift of the imputed distribution, in sample standard deviations.
  Default `1.8` (`"minprob"` only).

- width:

  Standard deviation of the imputed distribution, as a fraction of the
  sample standard deviation. Default `0.3` (`"minprob"` only).

- q:

  Quantile used by `"mindet"`. Default `0.01`.

- seed:

  Random seed, so a `"minprob"` run is reproducible. Default `1234`.

## Value

The matrix with missing values filled, carrying a logical attribute
`imputed` (same dimensions) marking which cells were imputed.

## Examples

``` r
if (FALSE) { # \dontrun{
mat_i <- impute_quant(mat_n, method = "minprob")
sum(attr(mat_i, "imputed"))
} # }
```
