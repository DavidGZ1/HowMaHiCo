# Batch-read every DIA-NN `report.tsv` under a folder and merge them

Recursively lists `folder` for `report.tsv` files, derives each one's
sample name from its parent subfolder, reads them all with
[`fp_read_psm()`](https://davidgz1.github.io/HowMaHiCo/reference/fp_read_psm.md)
(the same generic tsv reader used by the FragPipe loader — the two
formats only diverge once parsed into `pep_all` shape), and row-binds
the result.

## Usage

``` r
diann_read_tsv_batch(folder, testmode = FALSE)
```

## Arguments

- folder:

  Top-level directory to search recursively for `report.tsv` files.

- testmode:

  Logical; passed through to
  [`fp_read_psm()`](https://davidgz1.github.io/HowMaHiCo/reference/fp_read_psm.md)
  (loads only the first ~100 rows per file when `TRUE`, for fast
  iteration).

## Value

The merged raw DIA-NN report data frame across every file found, with
`Sample_fp` identifying the source subfolder of each row.

## Examples

``` r
if (FALSE) { # \dontrun{
diann_read_tsv_batch(file.path("2_data", "diann"), testmode = FALSE)
} # }
```
