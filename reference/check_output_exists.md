# Check whether any of the report's standard output files already exist

Looks for the full set of result files the report writes (`pep_all.csv`,
`seq_by_condition.xlsx`, the upset/overlap tables, etc.) inside `dir`,
and throws an error listing every match if any are found and
`overwrite = FALSE`. Complements
[`check_file_exists()`](https://davidgz1.github.io/HowMaHiCo/reference/check_file_exists.md)
— checking the whole output set at once makes it easier to surface every
conflict in one pass rather than failing partway through a render.

## Usage

``` r
check_output_exists(dir, overwrite = FALSE)
```

## Arguments

- dir:

  Directory where the results should be stored.

- overwrite:

  Logical; whether to allow overwriting existing files.

## Value

Invisible `NULL`; called for its side effects
([`stop()`](https://rdrr.io/r/base/stop.html)/[`warning()`](https://rdrr.io/r/base/warning.html)).

## Examples

``` r
if (FALSE) { # \dontrun{
check_output_exists("3_results/all", overwrite = FALSE)
} # }
```
