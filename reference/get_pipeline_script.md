# Copy the guided analysis-pipeline script to the working directory

Writes the runnable, commented walkthrough shipped in the package's
`inst/scripts/` to the working directory, where it can be edited and
sourced. It takes a project from raw search-engine output through the
annotation table, the cached `pep_all` and on to rendered HTML reports,
and every report is produced with
[`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md)
rather than by opening a template and knitting it by hand.

## Usage

``` r
get_pipeline_script(file = "howmahico_pipeline.R", overwrite = FALSE)
```

## Arguments

- file:

  Destination path for the copied script.

- overwrite:

  Logical; overwrite `file` if it already exists.

## Value

The destination path, invisibly.

## Details

The script starts in demo mode (`RUN_DEMO <- TRUE`): sourced as-is it
runs end to end against the simulated FragPipe dataset shipped in the
package, so a fresh install can be exercised before any real data is
involved. Setting `RUN_DEMO <- FALSE` switches it to the `CONFIG` block
at the top.

The sibling of
[`get_report_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_report_template.md)
(which copies a report skeleton) and
[`get_dictionary_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dictionary_template.md)
(which copies the custom-parser dictionary).
[`vignette("howmahico")`](https://davidgz1.github.io/HowMaHiCo/articles/howmahico.md)
narrates the same walkthrough without running it.

## Examples

``` r
if (FALSE) { # \dontrun{
get_pipeline_script("howmahico_pipeline.R")
# then open it, keep RUN_DEMO = TRUE, and source it to see a full run
} # }
```
