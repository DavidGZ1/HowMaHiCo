# Join parsed DIA-NN results to the sample annotation table

DIA-NN counterpart to
[`fp_annotate()`](https://davidgz1.github.io/HowMaHiCo/reference/fp_annotate.md)
— always operates in `"combined_file"`-equivalent mode (DIA-NN's
`report.tsv` always carries a `Source_file`/`Run` column), so the merge
always matches on `Sample_fp` + `Source_file`. Validates the annotation
table, compares matched (`Sample_fp`, `Source_file`) pairs and warns
about any that will be dropped, then inner-joins and drops empty factor
levels.

## Usage

``` r
diann_annotate(input, annotation)
```

## Arguments

- input:

  Output of
  [`diann_parse_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/diann_parse_pep_all.md).

- annotation:

  Annotation data frame; must contain at least `Condition`,
  `BioReplicate`, `TechReplicate`, `Sample`, `Sample_fp`, `Source_file`.

## Value

The inner join of `annotation` and `input`, with `Sample_ID` relocated
to the end and empty factor levels dropped.

## Examples

``` r
if (FALSE) { # \dontrun{
diann_annotate(pep_parsed, annotation)
} # }
```
