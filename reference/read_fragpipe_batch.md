# Batch-read FragPipe `psm.tsv` files and merge them

Reads all FragPipe `psm.tsv` files and row-binds the result. Three input
modes are supported (checked in priority order):

## Usage

``` r
read_fragpipe_batch(
  folder = NULL,
  annotation = NULL,
  files = NULL,
  testmode = FALSE
)
```

## Arguments

- folder:

  Top-level directory. Required when using the `annotation` or scan-all
  modes; unused when `files` is supplied.

- annotation:

  Optional annotation data frame (output of
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md)).
  When provided without `files`, only `Sample_fp` entries present in
  `annotation` are read.

- files:

  Optional character vector of `psm.tsv` file paths or parent folder
  paths to read directly.

- testmode:

  Logical; passed through to
  [`read_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/read_fragpipe.md)
  (loads only the first ~100 rows per file when `TRUE`, for fast
  iteration).

## Value

The merged raw PSM data frame across every file found, with `Sample_fp`
identifying the source subfolder of each row.

## Details

1.  **`files`** — character vector of `psm.tsv` file paths or their
    parent folder paths; sample names are taken from the immediate
    parent folder.

2.  **`annotation`** — only the `Sample_fp` entries listed in the
    annotation table are read from `folder`; warns about any annotated
    samples not found on disk.

3.  **neither** — `folder` is scanned recursively for every `psm.tsv`
    (original default behaviour).

## Examples

``` r
if (FALSE) { # \dontrun{
# scan entire folder
read_fragpipe_batch(file.path("2_data", "fragpipe_dda_combined"), testmode = FALSE)

# restrict to annotated samples only
read_fragpipe_batch(folder = "2_data", annotation = annot)

# provide paths explicitly
read_fragpipe_batch(files = c("2_data/fragpipe/JY_1/psm.tsv", "2_data/fragpipe/JY_2"))
} # }
```
