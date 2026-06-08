# Render an annotation table as an interactive HTML datatable

Thin wrapper around
[`DT::datatable()`](https://rdrr.io/pkg/DT/man/datatable.html) with the
report's standard display options (top filters, fixed header, no
rownames).

## Usage

``` r
print_annot(input)
```

## Arguments

- input:

  Annotation data frame, typically the output of
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md).

## Value

A [`DT::datatable`](https://rdrr.io/pkg/DT/man/datatable.html)
htmlwidget.

## Examples

``` r
if (FALSE) { # \dontrun{
print_annot(read_annot(file.path("1_documentation", params$AnnotationFile)))
} # }
```
