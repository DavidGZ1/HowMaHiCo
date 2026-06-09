# Read one DIA-NN `report.tsv` file

Thin wrapper around
[`read_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/read_fragpipe.md)
for API symmetry — DIA-NN report files use the same generic TSV format
as FragPipe PSM files; the two loaders only diverge during the parse
step
([`parse_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_diann.md)
vs
[`parse_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_fragpipe.md)).

## Usage

``` r
read_diann(folder, samplename, testmode = FALSE)
```

## Arguments

- folder:

  Path to the `report.tsv` file to read.

- samplename:

  Sample identifier to record in the new `Sample_fp` column.

- testmode:

  Logical; if `TRUE`, reads only the first ~100 rows.

## Value

The tsv contents as a data frame, with `Sample_fp` added and relocated
to the first column.

## Examples

``` r
if (FALSE) { # \dontrun{
read_diann("2_data/diann/JY/report.tsv", "JY", testmode = FALSE)
} # }
```
