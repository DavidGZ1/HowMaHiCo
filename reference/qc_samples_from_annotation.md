# Read the QC-control samples from an annotation file

Returns the `Sample` values that the annotation flags as experiment QC
controls in `qc_column` (`TRUE`, `T`, `1`, `QC`, `qc`, `yes` or `Yes`).
This is how `05_quality_score` and `09_overview` turn their `QCColumn`
param into the `qc_samples` of
[`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md).
A missing file, an unreadable annotation, an empty `qc_column` or a
column the annotation does not have all give an empty vector, because QC
tagging is optional.

## Usage

``` r
qc_samples_from_annotation(annotation_file, qc_column = "QC")
```

## Arguments

- annotation_file:

  Path to the annotation csv (read with
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md)).

- qc_column:

  Name of the flag column (default `"QC"`).

## Value

A character vector of QC `Sample` names (possibly empty).

## Examples

``` r
if (FALSE) { # \dontrun{
qc_samples_from_annotation("1_documentation/sample_annotation.csv", "QC")
} # }
```
