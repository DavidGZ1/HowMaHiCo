# Join parsed DIA-NN results to the sample annotation table

DIA-NN counterpart to
[`annotate_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_fragpipe.md)
— always operates in `"combined_file"`-equivalent mode (DIA-NN's
`report.tsv` always carries a `Source_file`/`Run` column), so the merge
always matches on `Sample_fp` + `Source_file`. Validates the annotation
table, compares matched (`Sample_fp`, `Source_file`) pairs and warns
about any that will be dropped, then inner-joins and drops empty factor
levels.

## Usage

``` r
annotate_diann(input, annotation)
```

## Arguments

- input:

  Output of
  [`parse_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_diann.md).

- annotation:

  Annotation data frame; must contain at least `Condition`,
  `BioReplicate`, `TechReplicate`, `Sample`, `Sample_fp`, `Source_file`.

## Value

The inner join of `annotation` and `input`, with `Sample_ID` relocated
to the end and empty factor levels dropped.

## Examples

``` r
if (FALSE) { # \dontrun{
annotate_diann(pep_parsed, annotation)
} # }
```
