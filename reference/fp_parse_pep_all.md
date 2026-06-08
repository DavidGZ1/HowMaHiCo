# Parse raw FragPipe PSM results into `pep_all` format

Reformats column names, derives the shared `pep_all` columns
(`PeptideID`, `Log2Area`, `Length_range`, `Nter`/`Cter`, `ppm`,
`Source_file`, ...), and selects/renames/reorders columns to converge on
the unified schema shared with the DIA-NN and PEAKS loaders.

## Usage

``` r
fp_parse_pep_all(input, shortpep_range = c(8, 13))
```

## Arguments

- input:

  Output of
  [`fp_read_psm_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/fp_read_psm_batch.md).

- shortpep_range:

  Length 2 vector `c(min, max)` defining the `Length_range`
  classification window (8-13 AAs for HLA-I).

## Value

The input reshaped into `pep_all` long format.

## Details

Note FragPipe results are read at the **PSM level**, not the peptide
level — FDR is therefore applied only at the PSM level here; treat
downstream FragPipe peptide counts with that caveat in mind.

## Examples

``` r
if (FALSE) { # \dontrun{
fp_parse_pep_all(fp_read_psm_batch(folder), shortpep_range = c(8, 13))
} # }
```
