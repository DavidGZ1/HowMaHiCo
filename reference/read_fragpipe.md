# Read one FragPipe `psm.tsv` or DIA-NN `report.tsv` file

Reads a single search-engine tsv with
[`readr::read_tsv()`](https://readr.tidyverse.org/reference/read_delim.html)
and tags every row with `samplename`. Shared internally by both the
FragPipe and DIA-NN batch readers — the two formats only diverge once
the per-sample frames are parsed into `pep_all` shape.

## Usage

``` r
read_fragpipe(folder, samplename, testmode = FALSE)
```

## Arguments

- folder:

  Path to the tsv file to read.

- samplename:

  Sample identifier to record in the new `Sample_fp` column (derived
  from the file's parent folder name by the batch reader).

- testmode:

  Logical; if `TRUE`, keeps only the first ~100 rows per run for fast
  iteration (can break downstream correlation plots on tiny subsets).

## Value

The tsv contents as a data frame, with `Sample_fp` added and relocated
to the first column.

## Details

With `testmode = TRUE` the file is read in full and then reduced to the
first ~100 rows **per run**, so that a combined export (one `psm.tsv`
holding every run) still yields every sample of the experiment. Test
mode therefore no longer saves file-reading time on combined exports; it
produces a small, representative dataset for fast rendering.

## Examples

``` r
if (FALSE) { # \dontrun{
read_fragpipe("2_data/fragpipe_dda_combined/JY/psm.tsv", "JY", testmode = FALSE)
} # }
```
