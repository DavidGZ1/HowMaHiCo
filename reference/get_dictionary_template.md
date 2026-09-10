# Copy the custom-parser dictionary template to the working directory

Writes the fill-in YAML dictionary template (shipped in the package's
`inst/extdata/dictionaries/`) to the working directory so it can be
edited to describe a new tabular search-engine export. The sibling of
[`get_report_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_report_template.md)
for the dictionary-driven `software = "custom"` path (see
[`parse_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_unified.md)
and
[`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)).

## Usage

``` r
get_dictionary_template(file = "howmahico_dictionary.yaml", overwrite = FALSE)
```

## Arguments

- file:

  Destination path for the copied template.

- overwrite:

  Logical; overwrite `file` if it already exists.

## Value

The destination path, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
get_dictionary_template("my_tool.yaml")
# edit my_tool.yaml, then:
build_pep_all("custom", folder_data = "2_data", annotation = annot,
              dictionary = "my_tool.yaml", file_rda = "2_data/pep_all.rda")
} # }
```
