# Batch-read a generic per-sample tabular export

Reads one delimited file per sample subfolder and row-binds the result,
tagging each row with `Sample_fp` (the subfolder name). The
dictionary-driven counterpart of
[`read_fragpipe_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_fragpipe_batch.md)
/
[`read_diann_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_diann_batch.md),
with the filename and delimiter taken from the dictionary's `read:`
block instead of being hard-coded. Three input modes are checked in
priority order:

## Usage

``` r
read_custom_batch(
  folder = NULL,
  annotation = NULL,
  files = NULL,
  file = "results.tsv",
  delim = "\t",
  testmode = FALSE
)
```

## Arguments

- folder:

  Top-level directory. Required for the `annotation` and scan-all modes;
  unused when `files` is supplied.

- annotation:

  Optional annotation data frame (output of
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md)).
  When provided without `files`, only its `Sample_fp` entries are read.

- files:

  Optional character vector of file paths or parent folder paths.

- file:

  Filename to read inside each sample subfolder (e.g. `"psm.tsv"`).

- delim:

  Field delimiter passed to
  [`readr::read_delim()`](https://readr.tidyverse.org/reference/read_delim.html)
  (`"\t"` for tsv, `","` for csv).

- testmode:

  Logical; if `TRUE`, keeps only the first ~100 rows per run
  (auto-detected `Run`/`Spectrum` column, else per file).

## Value

The merged raw data frame across every file found, with `Sample_fp`
identifying the source subfolder of each row.

## Details

1.  **`files`** — character vector of file paths or their parent
    folders; sample names are taken from the immediate parent folder.

2.  **`annotation`** — only `Sample_fp` entries listed in the annotation
    table are read from `folder`; warns about annotated samples not
    found on disk.

3.  **neither** — `folder` is scanned recursively for every file named
    `file`.

## Examples

``` r
if (FALSE) { # \dontrun{
read_custom_batch(folder = "2_data/my_export", annotation = annot,
                  file = "results.tsv", delim = "\t")
} # }
```
