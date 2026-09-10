# Read and validate a HowMaHiCo parser dictionary

Loads a YAML dictionary describing how to map a tabular search-engine
export onto the `pep_all` schema, fills in defaults, and validates the
required keys. See
[`parse_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_unified.md)
for the engine that consumes it and
[`get_dictionary_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dictionary_template.md)
for a fill-in template.

## Usage

``` r
read_dictionary(path)
```

## Arguments

- path:

  Path to a YAML dictionary file.

## Value

The dictionary as a normalized list (defaults filled in).

## Details

A dictionary has these keys:

- `found_by` — the `Found_By` label written into every row (required).

- `columns` — a `target: source` mapping (pep_all column : raw column);
  must cover at least `Sequence`, `Peptide`, `Area`, and `Length` (the
  last only when `derive.length_from_sequence` is not `true`).

- `mode` — `"individual_files"` (join on `Sample_fp`, default) or
  `"combined_file"` (join on `Sample_fp` + `Source_file`; then also map
  `Source_file`).

- `read$file` / `read$delim` — filename to read in each sample subfolder
  and its delimiter (defaults `"results.tsv"`, tab).

- `derive$length_from_sequence` — if `true`,
  `Length <- nchar(Sequence)`.

- `derive$format_charge` — if `true` (default),
  `Charge <- paste0("+ ", Charge)`.

- `derive$peptide_id` — column names pasted into `PeptideID` (default
  `c("ProteinFirst", "m_z", "Charge")`).

## Examples

``` r
if (FALSE) { # \dontrun{
dict <- read_dictionary(
  system.file("extdata", "dictionaries", "fragpipe.yaml", package = "HowMaHiCo")
)
} # }
```
