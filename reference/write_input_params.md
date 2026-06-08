# Write a report's render parameters to csv

Builds a one-row-per-parameter long-format data frame — package version,
render timestamp, then every entry of `params` flattened to a string —
and writes it via
[`write.csv_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/write.csv_rawr.md).
Deliberately a plain `input_params.csv` rather than a prepended xlsx
sheet (a documented deviation from the style guide's "first sheet is
always `input_params`" convention): assigning the table to a local
variable named `input_params` lets
[`write.csv_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/write.csv_rawr.md)'s
`deparse(substitute())` filename trick produce exactly
`<prefix>_input_params.csv` / `input_params.csv` for free.

## Usage

``` r
write_input_params(params, folder, prefix = NULL)
```

## Arguments

- params:

  The Rmd `params` list passed to the report at render time.

- folder:

  Destination directory for the csv.

- prefix:

  Optional string prepended to the filename, forwarded to
  [`write.csv_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/write.csv_rawr.md).

## Value

Invisible `NULL`; called for its side effect of writing
`input_params.csv`.

## Details

Always called once per render from the template's final export block,
independent of `CsvSave`/xlsx exports — `input_params.csv` is part of
the "always written" tier alongside `pep_all.csv`/
`counts_pep_all_condition.csv`/`seq_by_condition.xlsx`.

## Examples

``` r
if (FALSE) { # \dontrun{
write_input_params(params, folder = FolderResults)
} # }
```
