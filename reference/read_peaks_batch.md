# Batch-read PEAKS export folders and merge them into raw long format

Indexes the PEAKS export subfolders (via
[`get_dirs_index_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dirs_index_peaks.md)),
selects which to read, then reads and row-binds each one with
[`read_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks.md).
Three input modes are supported (checked in priority order):

## Usage

``` r
read_peaks_batch(
  folder = NULL,
  annotation = NULL,
  files = NULL,
  instrument = "tims_tof"
)
```

## Arguments

- folder:

  Top-level directory containing the PEAKS export subfolders. Required
  when using `annotation` or scan-all modes; may be `NULL` when `files`
  is supplied.

- annotation:

  Optional annotation data frame (output of
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md)).
  When provided without `files`, only subfolders whose `basename` is in
  `annotation$Sample_peaks` are read.

- files:

  Optional character vector of PEAKS export folder paths to read
  directly, bypassing the directory index.

- instrument:

  Passed to
  [`read_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks.md);
  one of `"tims_tof"`, `"faims_orbi"`, `"orbi"`.

## Value

The raw long-format PEAKS data frame across every matched subfolder,
with `Sample_peaks` identifying the source subfolder of each row.

## Details

1.  **`files`** — character vector of PEAKS export folder paths; uses
    those directly, bypassing the directory index.

2.  **`annotation`** — filters the directory index to subfolders whose
    `basename` is listed in `annotation$Sample_peaks`.

3.  **neither** — all non-QC PEAKS subfolders under `folder` are read.

The metadata join (adding `Condition`, `BioReplicate`, `Sample`, etc.)
happens in
[`annotate_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_peaks.md),
not here. This function returns the raw long-format PEAKS data only.

## Examples

``` r
if (FALSE) { # \dontrun{
read_peaks_batch(file.path("2_data", "peaks_xpro"), annotation,
                 instrument = "tims_tof")

# explicit folder paths
read_peaks_batch(files = c("peaks_xpro/JY_01", "peaks_xpro/JY_02"))
} # }
```
