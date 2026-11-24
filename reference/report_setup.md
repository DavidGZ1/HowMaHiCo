# Set up the objects a HowMaHiCo report works on

The setup step shared by the focused report templates
(`01_mhc_overview`, `02_prot_all`, `03_lcms_qc`, `04_pepchem`,
`05_quant_stats`), as an ordinary function so that a report can be run,
chunk by chunk, outside a knit. It derives the peptide-length window and
palette, the output folders, loads (or builds) `pep_all`, and derives
`pep_short` plus the grouping vectors every section reuses, then assigns
all of them into `envir`.

## Usage

``` r
report_setup(params, envir = parent.frame())
```

## Arguments

- params:

  Named list of report parameters, normally from
  [`report_params()`](https://davidgz1.github.io/HowMaHiCo/reference/report_params.md)
  (inside a knit, the `params` rmarkdown provides). Missing optional
  entries (`PepAllSource`, `InteractivePlots`, `ResultsOverwrite`,
  `Subset`, ...) fall back to the template defaults.

- envir:

  Environment the objects are assigned into. Defaults to the calling
  frame: the knit environment in a report, the global environment at the
  console.

## Value

Invisibly, a named list of the assigned objects: `shortpep_range`,
`shortpep_palette`, `shortpep_colors`, `interactive_plots`, `subset`,
`FolderResults`, `FolderFigures`, `result_prefix`, `file_rda`,
`pep_all`, `pep_short`, `samples`, `conditions`, `n_conditions`,
`bioreplicates`, `comp_condition`, `phis_nrow` and `phis_ncol`.

## Details

`pep_all` is obtained according to `params$PepAllSource`:

- `"cached"` (default): load `<FolderData>/<Subset>_pep_all.rda`.

- `"rda"`: load the file given by `params$PepAllFile`.

- `"build"`: parse the raw search output with
  [`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
  (reading `params$AnnotationFile` from `params$FolderDocumentation`)
  and write the cache.

To step through a report interactively:

    library(HowMaHiCo)
    params <- report_params("03_lcms_qc", Subset = "dda_all", FolderData = "2_data")
    report_setup(params)   # pep_all, pep_short, shortpep_range, ... now exist
    # then run the remaining chunks of the skeleton (see get_report_template())

## See also

[`report_params()`](https://davidgz1.github.io/HowMaHiCo/reference/report_params.md),
[`get_report_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_report_template.md),
[`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md)

## Examples

``` r
if (FALSE) { # \dontrun{
params <- report_params("01_mhc_overview", Subset = "dda_all",
                        FolderData = "2_data", FolderResults = "3_results")
report_setup(params)
table(pep_all$Condition)
} # }
```
