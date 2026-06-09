# Batch-read and annotate every PEAKS export folder into `pep_all` format

Indexes the PEAKS export subfolders (via the vendored
[`get_dirs_index_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dirs_index_peaks.md)),
selects which to read, then reads and joins each one with
[`read_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks.md),
derives the shared `pep_all` columns
(`ProteinFirst`/`GeneFirst`/`OrganismFirst`, `PeptideID`, `Log2Area`,
`Length_range`), drops decoys, and warns about any unmatched samples.

## Usage

``` r
read_peaks_batch(
  folder = NULL,
  annotation = NULL,
  files = NULL,
  instrument = "tims_tof",
  shortpep_range = c(8, 13)
)
```

## Arguments

- folder:

  Top-level directory containing the PEAKS export subfolders. Required
  when using `annotation` mode; may be `NULL` when `files` is supplied.

- annotation:

  Annotation data frame (output of
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md),
  joined with
  [`get_dirs_index_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dirs_index_peaks.md)'s
  `path_full` column for matching). Required for the metadata join in
  both modes.

- files:

  Optional character vector of PEAKS export folder paths (relative to
  [`getwd()`](https://rdrr.io/r/base/getwd.html)). When provided,
  bypasses the directory index and reads those folders directly.

- instrument:

  Passed to
  [`read_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks.md);
  one of `"tims_tof"`, `"faims_orbi"`, `"orbi"`.

- shortpep_range:

  Length 2 vector `c(min, max)` defining the `Length_range`
  classification window (8-13 AAs for HLA-I).

## Value

The unified `pep_all`-format long data frame for every matched PEAKS
sample.

## Details

Two input modes are supported for selecting which export folders to read
(checked in priority order):

1.  **`files`** — character vector of PEAKS export folder paths
    (relative to [`getwd()`](https://rdrr.io/r/base/getwd.html)); uses
    those directly, bypassing the directory index.

2.  **`annotation`** — filters the directory index to `path_full`
    entries present in `annotation` (original default behaviour).

`annotation` is always required for the metadata join (adds `Condition`,
`BioReplicate`, `Sample`, etc. to the output).

## Examples

``` r
if (FALSE) { # \dontrun{
read_peaks_batch(file.path("2_data", "peaks_xpro"), annotation,
                 instrument = params$Instrument)

# explicit folder paths
read_peaks_batch(files = c("peaks_xpro/JY_01", "peaks_xpro/JY_02"),
                 annotation = annot)
} # }
```
