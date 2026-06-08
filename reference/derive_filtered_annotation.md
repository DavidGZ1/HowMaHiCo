# Derive a Condition-filtered copy of a sample annotation file

Reads `annotation_file` from `folder`, keeps only rows whose `Condition`
matches `pattern` (via [`grepl()`](https://rdrr.io/r/base/grep.html)),
and writes the result alongside it as `<stem>_<suffix>.csv` — the
preprocessing step `00_knit_reports.R` ran once to derive the
`_jy`/`_plasma` annotation subsets from `_all` before batch-rendering
per-subset reports.

## Usage

``` r
derive_filtered_annotation(
  annotation_file,
  folder,
  pattern,
  suffix = tolower(pattern)
)
```

## Arguments

- annotation_file:

  Name of the source annotation csv (in `folder`), e.g.
  `"sample_annotation_dda_all.csv"`.

- folder:

  Directory containing `annotation_file` (and where the filtered copy is
  written), e.g. `"1_documentation"`.

- pattern:

  Regular expression matched against `Condition` via
  [`grepl()`](https://rdrr.io/r/base/grep.html) to select rows, e.g.
  `"JY"` or `"Plasma"`.

- suffix:

  Suffix appended to the filename stem to name the filtered copy
  (defaults to `tolower(pattern)`).

## Value

The path to the written filtered annotation csv (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
derive_filtered_annotation("sample_annotation_dda_all.csv", "1_documentation", "JY")
derive_filtered_annotation("sample_annotation_dda_all.csv", "1_documentation", "Plasma")
} # }
```
