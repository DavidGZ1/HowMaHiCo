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
  `annotation$Sample_folder` are read (`Sample_peaks` is used instead
  when the table predates that column, which is the
  one-folder-per-sample layout where the two keys coincide).

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
    `basename` is listed in `annotation$Sample_folder` (falling back to
    `Sample_peaks` when the table has no `Sample_folder`).

3.  **neither** — all non-QC PEAKS subfolders under `folder` are read.

**The folder key and the sample key are not the same thing for PEAKS.**
One export folder normally holds *several* samples, as one
`Area#<sample>` column each inside its `peptide.csv`, and
[`read_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks.md)
turns those suffixes into `Sample_peaks`. So `Sample_folder` selects the
folders here, while `Sample_peaks` is what
[`annotate_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_peaks.md)
later joins the metadata on. Keying the folder filter on `Sample_peaks`
(as this did before v0.22.0) matched no folder at all whenever the two
differed, and the empty read then died inside
[`parse_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_peaks.md)
with `object 'Accession' not found`.

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
