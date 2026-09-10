# Between-sample normalization of a log2 intensity matrix

HLA pulldown yield varies by orders of magnitude between samples, so
without between-sample normalization a loading difference is
indistinguishable from biology. `"median"` (the default) removes only a
per-sample offset — the minimal assumption — and is implemented in base
R so the default path has no Bioconductor dependency. `"quantile"`,
`"cyclicloess"` and `"scale"` delegate to
[`limma::normalizeBetweenArrays()`](https://rdrr.io/pkg/limma/man/normalizebetweenarrays.html);
they additionally force the *shape* of the distributions to agree, which
assumes most features do not change — a strong assumption in an on/off
ligand landscape, hence not the default.

## Usage

``` r
normalize_quant(
  mat,
  method = c("median", "quantile", "cyclicloess", "scale", "none")
)
```

## Arguments

- mat:

  Numeric matrix of log2 intensities (`NA`s allowed).

- method:

  One of `"median"` (default), `"quantile"`, `"cyclicloess"`, `"scale"`,
  `"none"`.

## Value

The normalized matrix (same dimensions and dimnames, `NA`s preserved).

## Examples

``` r
if (FALSE) { # \dontrun{
mat_n <- normalize_quant(mat_f, method = "median")
} # }
```
