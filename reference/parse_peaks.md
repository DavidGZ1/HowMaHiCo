# Parse raw PEAKS results into `pep_all` format

Derives the shared `pep_all` columns (`ProteinFirst`/`GeneFirst`/
`OrganismFirst`, `PeptideID`, `Log2Area`, `Length_range`, `Found_By`)
from the output of
[`read_peaks_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks_batch.md)
and selects/reorders columns to converge on the unified schema shared
with the FragPipe and DIA-NN loaders.

## Usage

``` r
parse_peaks(input, shortpep_range = c(8, 13))
```

## Arguments

- input:

  Output of
  [`read_peaks_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks_batch.md).

- shortpep_range:

  Length 2 vector `c(min, max)` defining the `Length_range`
  classification window (8-13 AAs for HLA-I).

## Value

The input reshaped into `pep_all` long format (without annotation
columns — call
[`annotate_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_peaks.md)
next).

## Examples

``` r
if (FALSE) { # \dontrun{
parse_peaks(read_peaks_batch(folder, annotation), shortpep_range = c(8, 13))
} # }
```
