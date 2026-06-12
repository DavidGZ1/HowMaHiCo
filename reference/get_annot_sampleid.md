# Enrich an annotation table with Sample_ID from a Bruker HyStar sample list

Reads a Bruker HyStar sample list (xlsx), extracts `Result.Path` and
`Sample.Comment`, derives the run name from the path, and inner-joins to
the annotation table on `Source_file`, replacing any existing
`Sample_ID`.

## Usage

``` r
get_annot_sampleid(annotation, file_sample_list)
```

## Arguments

- annotation:

  Annotation data frame (e.g. from
  [`get_annot_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_fragpipe.md)
  or
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md)).

- file_sample_list:

  Path to the Bruker HyStar sample list `.xlsx` file.

## Value

`annotation` with the `Sample_ID` column filled from `Sample.Comment` in
the sample list. Rows without a match are dropped (inner join).

## Examples

``` r
if (FALSE) { # \dontrun{
annot <- get_annot_fragpipe("2_data")
get_annot_sampleid(annot, "1_documentation/sample_list.xlsx")
} # }
```
