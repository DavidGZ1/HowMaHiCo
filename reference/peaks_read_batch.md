# Batch-read and annotate every PEAKS export folder into `pep_all` format

Indexes the PEAKS export subfolders under `folder` (via the vendored
[`get_dirs_index_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dirs_index_peaks.md)),
filters to those present in `annotation`, reads and joins each one with
[`read_pep_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/read_pep_peaks.md),
then derives the shared `pep_all` columns
(`ProteinFirst`/`GeneFirst`/`OrganismFirst`, `PeptideID`, `Log2Area`,
`Length_range`), drops decoys, and warns about any samples that could
not be matched to the annotation table.

## Usage

``` r
peaks_read_batch(
  folder,
  annotation,
  instrument = "tims_tof",
  shortpep_range = c(8, 13)
)
```

## Arguments

- folder:

  Top-level directory containing the PEAKS export subfolders.

- annotation:

  Annotation data frame (output of
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md),
  joined with
  [`get_dirs_index_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dirs_index_peaks.md)'s
  `path_full` column for matching).

- instrument:

  Passed to
  [`read_pep_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/read_pep_peaks.md);
  one of `"tims_tof"`, `"faims_orbi"`, `"orbi"`.

- shortpep_range:

  Length 2 vector `c(min, max)` defining the `Length_range`
  classification window (8-13 AAs for HLA-I).

## Value

The unified `pep_all`-format long data frame for every matched PEAKS
sample.

## Examples

``` r
if (FALSE) { # \dontrun{
peaks_read_batch(file.path("2_data", "peaks_xpro"), annotation,
                 instrument = params$Instrument)
} # }
```
