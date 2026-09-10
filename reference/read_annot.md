# Read, validate, and reformat a sample annotation table

Reads the annotation csv, strips `.d`/`.raw` extensions from
`Source_file` (if present), checks that the required columns are
present, harmonizes the data-folder column across search engines (see
below), normalizes `Sample_peaks` to match PEAKS' own export-naming
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
  one of `Sample_folder` (preferred) / `Sample_fp` / `Sample_peaks`.

## Value

The annotation data frame, with `Source_file` extensions stripped,
`Sample_folder`/`Sample_fp`/`Sample_peaks` all populated (`Sample_peaks`
with hyphens/spaces normalized to underscores), and every character
column converted to a factor ordered by first appearance.

## Details

**One annotation format for every software.** The column naming the data
subfolder of each sample is `Sample_folder`, whatever the search engine.
The historical, engine-specific names are still accepted: a table
providing `Sample_fp` (FragPipe/DIA-NN/custom) or `Sample_peaks` (PEAKS)
loads unchanged. Whichever is present, the others are derived:
`Sample_fp` is a verbatim copy of `Sample_folder`, and `Sample_peaks` is
a copy with PEAKS' hyphen/space normalization applied — so the loaders,
which key on `Sample_fp`/`Sample_peaks`, keep working either way. A
column the user supplied is never overwritten.

## Examples

``` r
if (FALSE) { # \dontrun{
read_annot(file.path("1_documentation", params$AnnotationFile))
} # }
```
