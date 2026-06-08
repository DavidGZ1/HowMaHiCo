# Batch-read every FragPipe `psm.tsv` under a folder and merge them

Recursively lists `folder` for `psm.tsv` files, derives each one's
sample name from its parent subfolder, reads them all with
[`fp_read_psm()`](https://davidgz1.github.io/HowMaHiCo/reference/fp_read_psm.md),
and row-binds the result.

## Usage

``` r
fp_read_psm_batch(folder, testmode = FALSE)
```

## Arguments

- folder:

  Top-level directory to search recursively for `psm.tsv` files.

- testmode:

  Logical; passed through to
  [`fp_read_psm()`](https://davidgz1.github.io/HowMaHiCo/reference/fp_read_psm.md)
  (loads only the first ~100 rows per file when `TRUE`, for fast
  iteration).

## Value

The merged raw PSM data frame across every file found, with `Sample_fp`
identifying the source subfolder of each row.

## Examples

``` r
if (FALSE) { # \dontrun{
fp_read_psm_batch(file.path("2_data", "fragpipe_dda_combined"), testmode = FALSE)
} # }
```
