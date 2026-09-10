# Auto-generate a skeleton annotation table from FragPipe psm.tsv files

Scans `dir_data` recursively for `psm.tsv` files, reads the `Spectrum`
column from each to derive unique `Source_file` names, and returns a
data frame with one row per source file ready to fill in (`Condition`,
`BioReplicate`, `TechReplicate`, `Sample`, `Sample_ID` are left blank).

## Usage

``` r
get_annot_fragpipe(dir_data)
```

## Arguments

- dir_data:

  Path to the root data folder containing FragPipe output subfolders
  (each with a `psm.tsv`).

## Value

A data frame with columns `Source_file`, `Sample_folder`, `Condition`,
`BioReplicate`, `TechReplicate`, `Sample`, `Sample_ID`, sorted by
`Source_file`.

## Examples

``` r
if (FALSE) { # \dontrun{
get_annot_fragpipe("2_data")
} # }
```
