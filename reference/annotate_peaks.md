# Join parsed PEAKS results to the sample annotation table

Validates that the annotation table has the minimal required columns,
inner-joins `input` with `annotation` on `Sample_peaks`, warns about any
unmatched samples, and filters out decoy identifications.

## Usage

``` r
annotate_peaks(input, annotation)
```

## Arguments

- input:

  Output of
  [`parse_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_peaks.md).

- annotation:

  Annotation data frame; must contain at least `Condition`,
  `BioReplicate`, `TechReplicate`, `Sample`, `Sample_peaks`.

## Value

The inner join of `annotation` and `input`, with decoys removed.

## Examples

``` r
if (FALSE) { # \dontrun{
annotate_peaks(parse_peaks(read_peaks_batch(folder, annotation)), annotation)
} # }
```
