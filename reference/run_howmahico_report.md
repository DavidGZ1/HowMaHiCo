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
  template = c("01_mhc_report", "02_mhc_upsets"),
  params,
  output_file,
  ...
)
```

## Arguments

- template:

  One of `"01_mhc_report"` (the main QC report) or `"02_mhc_upsets"`
  (the secondary overlap/UpSet report).

- params:

  Named list of report parameters, as declared in the template's YAML
  header (`SampleSet`, `AnnotationFile`, `Subset`, `FolderData`,
  `FolderResults`, `FolderFigures`, `Software`, `MHCclass`, ...). The
  report title is auto-generated from `SampleSet`, `Subset`, `MHCclass`,
  and the render date — no `Title` param needed. Key params: `MHCclass`
  — `"MHC1"` (8-13 AA window, default) or `"MHC2"` (12-25 AA window);
  overrides `ShortPeptideLengthMin`/`ShortPeptideLengthMax` when set to
  a recognised value. Pass `ProjectDir = "/absolute/path/to/project"` to
  resolve relative folder paths from that directory instead of the
  current working directory — useful when R is started from a
  subdirectory.

- output_file:

  Output HTML file path. Relative paths are resolved against
  `params$ProjectDir` (if supplied) or the current working directory at
  call time — never against the package-internal skeleton location.

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
  template = "01_mhc_report",
  params = list(SampleSet = "MEGF_035_K251128",
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
  run_howmahico_report(template = "01_mhc_report",
                       params = list(Subset = subset, ...),
                       output_file = paste0("01_report_main__hla1_", subset, ".html"))
}
} # }
```
