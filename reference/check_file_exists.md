# Check whether a single output file already exists

Throws an error if `file` already exists and `overwrite = FALSE`, or
warns (and proceeds) if it exists and `overwrite = TRUE`. Used as a
pre-flight guard before writing report outputs, so a re-render cannot
silently clobber a prior analysis run.

## Usage

``` r
check_file_exists(file, overwrite = FALSE)
```

## Arguments

- file:

  Path to the file to check, full path.

- overwrite:

  Logical; whether to allow overwriting an existing file.

## Value

Invisible `NULL`; called for its side effects
([`stop()`](https://rdrr.io/r/base/stop.html)/[`warning()`](https://rdrr.io/r/base/warning.html)).

## Examples

``` r
if (FALSE) { # \dontrun{
check_file_exists("3_results/all/pep_all.csv", overwrite = FALSE)
} # }
```
