# Parse raw FragPipe PSM results into `pep_all` format

Reformats column names, derives the shared `pep_all` columns
(`PeptideID`, `Log2Area`, `Length_range`, `Nter`/`Cter`, `ppm`,
`Source_file`, ...), and selects/renames/reorders columns to converge on
the unified schema shared with the DIA-NN and PEAKS loaders.

## Usage

``` r
parse_fragpipe(input, shortpep_range = c(8, 13))
```

## Arguments

- input:

  Output of
  [`read_fragpipe_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_fragpipe_batch.md).

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
parse_fragpipe(read_fragpipe_batch(folder), shortpep_range = c(8, 13))
} # }
```
