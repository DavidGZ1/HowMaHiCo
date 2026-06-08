# List and classify PEAKS export subfolders

Lists the subdirectories under `directory`, classifies each by export
type (PEAKS / PEAKS PTM / SPIDER / QC variants) and mode (DB / LIB)
inferred from the folder-naming convention, and extracts the project
name and PEAKS file number from the folder name.

## Usage

``` r
get_dirs_index_peaks(directory, recursive = TRUE, drop_unknowns = TRUE)
```

## Arguments

- directory:

  Path to the top-level folder containing PEAKS export subfolders.

- recursive:

  Passed to [`list.dirs()`](https://rdrr.io/r/base/list.files.html);
  whether to list subdirectories recursively.

- drop_unknowns:

  If `TRUE` (default), rows whose `Type` could not be classified (folder
  name doesn't match any known PEAKS export pattern) are dropped.

## Value

A data frame with one row per matching subdirectory and columns
`path_full`, `QC`, `Mode`, `Type`, `Project`, `File_peaks_nb`.

## Examples

``` r
if (FALSE) { # \dontrun{
get_dirs_index_peaks("2_data/peaks_xpro")
} # }
```
