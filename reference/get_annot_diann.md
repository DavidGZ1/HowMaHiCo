# Auto-generate a skeleton annotation table from DIA-NN report.tsv files

Scans `dir_data` recursively for `report.tsv` files, reads the `Run`
column from each to derive unique `Source_file` names, and returns a
data frame with one row per source file ready to fill in.

## Usage

``` r
get_annot_diann(dir_data)
```

## Arguments

- dir_data:

  Path to the root data folder containing DIA-NN output subfolders (each
  with a `report.tsv`).

## Value

A data frame with columns `Source_file`, `Sample_folder`, `Condition`,
`BioReplicate`, `TechReplicate`, `Sample`, `Sample_ID`, sorted by
`Source_file`.

## Examples

``` r
if (FALSE) { # \dontrun{
get_annot_diann("2_data")
} # }
```
