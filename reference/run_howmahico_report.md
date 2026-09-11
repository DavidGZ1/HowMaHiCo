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
  template = c("00_mhc_report", "00_mhc_upsets", "01_id_counts", "02_overlaps",
    "03_lcms_qc", "04_quant", "05_quality_score", "06_quant_stats", "07_pepchem",
    "08_prot_all"),
  params,
  output_file,
  ...
)
```

## Arguments

- template:

  Which report template to render. `"00_mhc_report"` is the all-in-one
  QC report (it parses the raw search files itself). The remaining
  templates are focused reports that render against a `pep_all` cache
  built once by
  [`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
  (or by `00_mhc_report`): `"00_mhc_upsets"` (per-sample overlap/UpSet),
  `"01_id_counts"` (general identification QC: counts, size
  distributions, motifs, PTM), `"02_overlaps"` (intra-Condition /
  cross-Condition / pairwise overlap), `"03_lcms_qc"` (RT/1k0/mz
  distributions, Score/ppm QC), `"04_quant"` (log2(Area) correlation,
  Area %CV), `"05_quality_score"` (per-sample immunopeptidomics quality
  score with a traffic-light overview) and `"06_quant_stats"` (advanced
  quantification: normalization, PCA/clustering and limma differential
  abundance between Conditions) and `"07_pepchem"` (peptide
  physicochemical properties: amino-acid composition, per-position
  residue frequency and descriptors such as GRAVY, compared between
  Conditions) and `"08_prot_all"` (protein level: source proteins per
  sample, ligands per protein, and any protein-level values the search
  engine reported).

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
  template = "00_mhc_report",
  params = list(SampleSet = "MEGF_035_K251128",
                AnnotationFile = "sample_annotation_dda_all.csv",
                Subset = "dda_all",
                FolderData = "/data/2_data",
                FolderResults = "/data/3_results",
                FolderFigures = "/data/4_figures",
                Software = "fragpipe_dda_combined"),
  output_file = "01_report_main__hla1_dda_all.html"
)

# Focused-report framework: build the pep_all cache once, then render any
# subset of the focused reports against it (no re-parsing per report).
annot <- read_annot("1_documentation/sample_annotation_dda_all.csv")
build_pep_all(software = "fragpipe_dda_combined", folder_data = "2_data",
              annotation = annot, shortpep_range = c(8, 13),
              file_rda = "2_data/dda_all_pep_all.rda")
focused_params <- list(SampleSet = "MEGF_035", Subset = "dda_all",
                       FolderData = "2_data", FolderResults = "3_results",
                       FolderFigures = "4_figures", Software = "fragpipe_dda_combined")
for (tmpl in c("01_id_counts", "02_overlaps", "03_lcms_qc", "04_quant",
                "05_quality_score", "06_quant_stats", "07_pepchem")) {
  run_howmahico_report(tmpl, params = focused_params,
                       output_file = paste0(tmpl, "__dda_all.html"))
}

# Batch-rendering pattern (preserves 00_knit_reports.R's 6-subset loop):
annot_jy <- derive_filtered_annotation("sample_annotation_dda_all.csv",
                                       "1_documentation", "JY")
for (subset in c("dda_all", "dda_jy", "dda_plasma")) {
  run_howmahico_report(template = "00_mhc_report",
                       params = list(Subset = subset, ...),
                       output_file = paste0("01_report_main__hla1_", subset, ".html"))
}
} # }
```
