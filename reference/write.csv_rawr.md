# Write a data frame to csv, named after the variable that was passed in

Looks up the name `input` was called with (via `deparse(substitute())`)
and writes it to `<folder>/<prefix>_<name>.csv` (or
`<folder>/<name>.csv` when `prefix` is `NULL`) — an intentional NSE
pattern that lets ~30 export call sites stay terse
(`write.csv_rawr(counts_pep_all_condition)`) while the output filename
always matches the object name.

## Usage

``` r
write.csv_rawr(input, folder, prefix = NULL)
```

## Arguments

- input:

  The data frame to write (NSE: its variable name becomes the filename).

- folder:

  Destination directory for the csv.

- prefix:

  Optional string prepended to the filename as `"<prefix>_<name>.csv"`;
  when `NULL` (the default) the filename is just `"<name>.csv"`.

## Value

Invisible `NULL`; called for its side effect of writing a csv.

## Details

Reconciles three near-duplicate report-inline variants (a plain
`folder = FolderResults`-defaulting version, and two that additionally
prefixed the filename with `params$Subset`) into one canonical signature
that takes both `folder` and an optional `prefix` explicitly.

## Examples

``` r
if (FALSE) { # \dontrun{
write.csv_rawr(counts_pep_all_condition, folder = FolderResults)
write.csv_rawr(counts_pep_all_wide, folder = FolderResults, prefix = params$Subset)
} # }
```
