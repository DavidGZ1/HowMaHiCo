# Join a dictionary-parsed table to the sample annotation

The generic counterpart of
[`annotate_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_fragpipe.md)
for the custom path: validates the annotation's minimal columns, warns
about samples present on only one side, and inner-joins on `Sample_fp`
(`"individual_files"`) or `Sample_fp` + `Source_file`
(`"combined_file"`). Unlike
[`annotate_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_fragpipe.md)
it relocates `Sample_ID` to the last column rather than after
`Is_Unique` (a generic export need not carry FragPipe's `Is_Unique`
column).

## Usage

``` r
annotate_unified(input, annotation, mode = "individual_files")
```

## Arguments

- input:

  Output of
  [`parse_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_unified.md).

- annotation:

  Annotation data frame; must contain at least `Condition`,
  `BioReplicate`, `TechReplicate`, `Sample`, `Sample_fp` (and
  `Source_file` when `mode = "combined_file"`).

- mode:

  `"individual_files"` (default) or `"combined_file"`.

## Value

The inner join of `annotation` and `input`.

## Examples

``` r
if (FALSE) { # \dontrun{
annotate_unified(parsed, annotation, mode = "individual_files")
} # }
```
