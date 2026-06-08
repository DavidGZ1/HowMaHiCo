# Read one FragPipe `psm.tsv`/DIA-NN `report.tsv` file

Reads a single search-engine tsv with
[`readr::read_tsv()`](https://readr.tidyverse.org/reference/read_delim.html)
(optionally truncated to the first ~100 rows for fast iteration via
`testmode`), and tags every row with `samplename`. Shared by both the
FragPipe and DIA-NN batch readers — the two formats only diverge once
the per-sample frames are parsed into `pep_all` shape.

## Usage

``` r
fp_read_psm(folder, samplename, testmode = FALSE)
```

## Arguments

- folder:

  Path to the tsv file to read.

- samplename:

  Sample identifier to record in the new `Sample_fp` column (derived
  from the file's parent folder name by the batch reader).

- testmode:

  Logical; if `TRUE`, reads only the first ~100 rows for fast iteration
  (can break downstream correlation plots on tiny subsets).

## Value

The tsv contents as a data frame, with `Sample_fp` added and relocated
to the first column.

## Examples

``` r
if (FALSE) { # \dontrun{
fp_read_psm("2_data/fragpipe_dda_combined/JY/psm.tsv", "JY", testmode = FALSE)
} # }
```
