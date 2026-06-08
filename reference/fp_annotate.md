# Join parsed FragPipe results to the sample annotation table

Validates that the annotation table has the minimal required columns,
compares the (`Sample_fp`, `Source_file`) pairs found in `input` vs.
`annotation` and warns about any that will be dropped on either side,
then inner-joins on the matching key appropriate for `mode` —
`Sample_fp` alone for `"individual_files"`, or `Sample_fp` +
`Source_file` for `"combined_file"` (FragPipe combined PSM).

## Usage

``` r
fp_annotate(input, annotation, mode = "individual_files")
```

## Arguments

- input:

  Output of
  [`fp_parse_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/fp_parse_pep_all.md).

- annotation:

  Annotation data frame; must contain at least `Condition`,
  `BioReplicate`, `TechReplicate`, `Sample`, `Sample_fp` (and
  `Source_file` when `mode = "combined_file"`).

- mode:

  One of `"individual_files"` (one folder per file, matched on
  `Sample_fp`) or `"combined_file"` (combined PSM, matched on
  `Sample_fp` + `Source_file`).

## Value

The inner join of `annotation` and `input`, with `Sample_ID` relocated
to the end and (for `"combined_file"` mode) empty factor levels dropped.

## Examples

``` r
if (FALSE) { # \dontrun{
fp_annotate(pep_parsed, annotation, mode = "combined_file")
} # }
```
