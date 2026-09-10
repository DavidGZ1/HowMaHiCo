# Parse a raw search-engine export into `pep_all` via a dictionary

The dictionary-driven counterpart of the built-in `parse_*()` loaders:
applies the `columns:` renames, sets the `Found_By` constant, and
derives the shared `pep_all` columns (`Length_range`, `Nter`/`Cter`,
`Log2Area`, `PeptideID`, and optionally `Length` and a formatted
`Charge`), then guards the result with the same `validate_pep_all()`
schema check the built-in loaders use. Reuses `compute_log2area()` so
zero `Area` maps to `NA` consistently with the other loaders.

## Usage

``` r
parse_unified(input, dictionary, shortpep_range = c(8, 13))
```

## Arguments

- input:

  A raw per-sample table, row-bound across samples and tagged with
  `Sample_fp` (e.g. the output of
  [`read_custom_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_custom_batch.md)).

- dictionary:

  Either a path to a YAML dictionary or an already-loaded dictionary
  list (see
  [`read_dictionary()`](https://davidgz1.github.io/HowMaHiCo/reference/read_dictionary.md)).

- shortpep_range:

  Length-2 numeric `c(min, max)` window for `Length_range`.

## Value

The input reshaped into `pep_all` long format.

## Examples

``` r
if (FALSE) { # \dontrun{
dict <- system.file("extdata", "dictionaries", "fragpipe.yaml", package = "HowMaHiCo")
read_custom_batch("2_data/my_export", file = "psm.tsv", delim = "\t") |>
  parse_unified(dict, shortpep_range = c(8, 13))
} # }
```
