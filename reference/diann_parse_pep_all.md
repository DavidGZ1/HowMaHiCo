# Parse raw DIA-NN report results into `pep_all` format

Reformats column names, derives the shared `pep_all` columns
(`PeptideID`, `Log2Area`, `Length_range`, `Nter`/`Cter`, `Mass`,
`Source_file`, ...), and selects/renames/reorders columns to converge on
the unified schema shared with the FragPipe and PEAKS loaders.

## Usage

``` r
diann_parse_pep_all(input, shortpep_range = c(8, 13))
```

## Arguments

- input:

  Output of
  [`diann_read_tsv_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/diann_read_tsv_batch.md).

- shortpep_range:

  Length 2 vector `c(min, max)` defining the `Length_range`
  classification window (8-13 AAs for HLA-I).

## Value

The input reshaped into `pep_all` long format.

## Details

Two columns are not directly reported by DIA-NN: `ppm` is a hardcoded
dummy (`= 0`, since DIA-NN reports no calculated m/z to derive a mass
error from); `Mass` *is* computed here (from
`Precursor.Mz`/`Precursor.Charge` via the standard mass formula) but is
**not** the calibrated/observed mass the other loaders report — check
this function directly if precision matters.

## Examples

``` r
if (FALSE) { # \dontrun{
diann_parse_pep_all(diann_read_tsv_batch(folder), shortpep_range = c(8, 13))
} # }
```
