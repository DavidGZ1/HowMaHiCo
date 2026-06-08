# Read, validate, and reformat a sample annotation table

Reads the annotation csv, strips `.d`/`.raw` extensions from
`Source_file` (if present), checks that the required columns are
present, normalizes `Sample_peaks` to match PEAKS' own export-naming
behavior (hyphens/spaces replaced by underscores), and sets factor
levels for every character column from the row order in the csv — this
is what gives downstream plots/tables their condition/sample ordering.

## Usage

``` r
read_annot(file_annot)
```

## Arguments

- file_annot:

  Path to a csv file with the annotation table, including at least the
  columns `Condition`, `BioReplicate`, `TechReplicate`, `Sample`, and
  one of `Sample_fp`/`Sample_peaks`.

## Value

The annotation data frame, with `Source_file` extensions stripped,
`Sample_peaks` hyphens/spaces normalized to underscores, and every
character column converted to a factor ordered by first appearance.

## Examples

``` r
if (FALSE) { # \dontrun{
read_annot(file.path("1_documentation", params$AnnotationFile))
} # }
```
