# Auto-generate a skeleton annotation table from a PEAKS export folder

PEAKS counterpart of
[`get_annot_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_fragpipe.md)
/
[`get_annot_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_diann.md):
indexes the search-result subfolders of a PEAKS export with the same
internal indexer
[`read_peaks_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks_batch.md)
uses to pick folders, drops the QC folders, and returns one row per
result folder ready to fill in.

## Usage

``` r
get_annot_peaks(dir_data, drop_qc = TRUE)
```

## Arguments

- dir_data:

  Path to the PEAKS export root folder (the one holding the
  `<project>_PEAKS_<nn>` result subfolders).

- drop_qc:

  Drop the `_QC_` folders (default `TRUE`) — they are not sample results
  and
  [`read_peaks_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks_batch.md)
  ignores them too.

## Value

A data frame with columns `Sample_folder`, `File_peaks_nb`, `Condition`,
`BioReplicate`, `TechReplicate`, `Sample`, `Sample_ID`, sorted by
`Sample_folder`.

## Details

**One row per folder is not necessarily one row per sample.** A PEAKS
export folder usually holds several samples, one `Area#<sample>` column
each inside its `peptide.csv`, and it is those suffixes that
[`annotate_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_peaks.md)
joins on. So for a multi-sample export, duplicate the folder's row once
per sample and add a `Sample_peaks` column naming each sample exactly as
its `Area#` column does; `Sample_folder` stays the same on every one of
those rows. With one folder per sample the two keys coincide and
[`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md)
derives `Sample_peaks` for you.

## Examples

``` r
if (FALSE) { # \dontrun{
get_annot_peaks("2_data/peaks_export")
} # }
```
