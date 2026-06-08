# Render a HowMaHiCo QC report from the installed package templates

Thin wrapper around
[`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html)
that locates one of the package's two report templates via
[`system.file()`](https://rdrr.io/r/base/system.file.html) and renders
it with the supplied `params`. One call renders one report — composable
(loop it for batch runs, see
[`derive_filtered_annotation()`](https://davidgz1.github.io/HowMaHiCo/reference/derive_filtered_annotation.md)/the
batch-rendering example below) and Docker-idiomatic ("one container run
= one job").

## Usage

``` r
run_howmahico_report(
  template = c("howmahico-report", "howmahico-upsets"),
  params,
  output_file,
  ...
)
```

## Arguments

- template:

  One of `"howmahico-report"` (the main QC report) or
  `"howmahico-upsets"` (the secondary overlap/UpSet report).

- params:

  Named list of report parameters, as declared in the template's YAML
  header (`Title`, `AnnotationFile`, `Subset`, `FolderData`,
  `FolderResults`, `FolderFigures`, `Software`, ...). Pass
  `ProjectDir = "/absolute/path/to/project"` to resolve relative folder
  paths from that directory instead of the current working directory —
  useful when R is started from a subdirectory (e.g. `0_code/`).

- output_file:

  Output HTML file path, forwarded to
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html).

- ...:

  Additional arguments forwarded to
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html)
  (e.g. `quiet`, `envir`).

## Value

The path to the rendered output file (invisibly), as returned by
[`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html).

## Details

`FolderData`/`FolderResults`/`FolderFigures` in `params` are **absolute
paths** (or paths relative to the current working directory at render
time) — unlike the legacy `0_code/`-era reports, the rendered template
no longer assumes a fixed project-root-relative layout, since it now
lives inside an installed package and can be rendered from anywhere.

## Examples

``` r
if (FALSE) { # \dontrun{
run_howmahico_report(
  template = "howmahico-report",
  params = list(Title = "Report: MHC1p evaluation - dda_all",
                SampleSet = "MEGF_035_K251128",
                AnnotationFile = "sample_annotation_dda_all.csv",
                Subset = "dda_all",
                FolderData = "/data/2_data",
                FolderResults = "/data/3_results",
                FolderFigures = "/data/4_figures",
                Software = "fragpipe_dda_combined"),
  output_file = "01_report_main__hla1_dda_all.html"
)

# Batch-rendering pattern (preserves 00_knit_reports.R's 6-subset loop):
annot_jy <- derive_filtered_annotation("sample_annotation_dda_all.csv",
                                       "1_documentation", "JY")
for (subset in c("dda_all", "dda_jy", "dda_plasma")) {
  run_howmahico_report(template = "howmahico-report",
                       params = list(Subset = subset, ...),
                       output_file = paste0("01_report_main__hla1_", subset, ".html"))
}
} # }
```
