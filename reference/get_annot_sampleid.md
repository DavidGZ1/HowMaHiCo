# Enrich an annotation table with Sample_ID from a Bruker HyStar sample list

Reads a Bruker HyStar sample list (xlsx), extracts `Result.Path` and
`Sample.Comment`, derives the run name from the path, and joins it to
the annotation table on `Source_file`, replacing any existing
`Sample_ID`.

## Usage

``` r
get_annot_sampleid(annotation, file_sample_list, keep_all = FALSE)
```

## Arguments

- annotation:

  Annotation data frame (e.g. from
  [`get_annot_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_fragpipe.md)
  or
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md)).

- file_sample_list:

  Path to the Bruker HyStar sample list `.xlsx` file.

- keep_all:

  Keep every annotation row (left join, unmatched `Sample_ID` left `NA`)
  instead of dropping the unmatched ones. Default `FALSE`, the
  historical inner-join behaviour.

## Value

`annotation` with the `Sample_ID` column filled from `Sample.Comment` in
the sample list. Rows without a match are dropped (inner join) unless
`keep_all = TRUE`.

## Details

The join is easy to get silently wrong — the two sides must agree on the
run naming, and with the default inner join a mismatch simply removes
rows. This function therefore warns when nothing matched (showing
example values from both sides) and when only some rows matched (naming
the ones dropped); `keep_all = TRUE` switches to a left join so no
annotation row is ever lost.

## Examples

``` r
if (FALSE) { # \dontrun{
annot <- get_annot_fragpipe("2_data")
get_annot_sampleid(annot, "1_documentation/sample_list.xlsx")
} # }
```
