# Getting started with HowMaHiCo

HowMaHiCo turns LC-immunopeptidomics search-engine output into
self-contained interactive HTML QC reports. It reads FragPipe, DIA-NN
and PEAKS exports (and, through a YAML dictionary, most other tabular
formats), normalises them into one long-format table called `pep_all`,
and renders parameterised report templates against it.

This article walks through a complete analysis. Everything here is also
available as a **runnable script**:

``` r

HowMaHiCo::get_pipeline_script("howmahico_pipeline.R")
```

That script starts in demo mode, so sourcing it as-is runs the whole
pipeline on a small simulated dataset shipped with the package — useful
for checking an install before pointing it at real data.

## Installation

``` r

remotes::install_github("DavidGZ1/HowMaHiCo")

# Optional: the advanced-quantification report (06) uses limma when available
BiocManager::install("limma")
```

Rendering reports needs pandoc, which RStudio bundles; outside RStudio,
install it separately. Without limma, report 06 still runs and falls
back to a Welch t-test.

## The shape of a run

    search output (psm.tsv / report.tsv / peptide.csv)
       |  read + parse + annotate
       v
    pep_all  ->  cached as <Subset>_pep_all.rda
       |  render
       v
    HTML reports  +  csv/xlsx tables  +  optional png figures

Two things drive everything: the **annotation table**, which says which
files belong to which experimental group, and the **`Software`**
parameter, which selects the loader.

## 1. The annotation table

Generate a skeleton with one row per data file, then fill in the
experimental columns by hand:

``` r

library(HowMaHiCo)

get_annot_fragpipe(dir_data = "2_data") |>            # or get_annot_diann() / get_annot_peaks()
  write.csv(row.names = FALSE, file = "1_documentation/sample_annotation.csv")
```

Open the csv and complete `Condition`, `BioReplicate`, `TechReplicate`
and `Sample_ID`. Two behaviours are worth knowing, because both are easy
to trip over:

- **Inclusion** — only samples listed in the table are read and
  reported. A sample sitting in the data folder but missing from the
  table is silently excluded, so the table is also how you subset a run.
- **Ordering** — Conditions, replicates and samples appear in every plot
  and table in the **row order of the csv**. Order the rows the way you
  want them displayed.

`Sample_ID` can also be filled from a Bruker HyStar sample list with
[`get_annot_sampleid()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_sampleid.md).

Here is the completed annotation table that ships with the simulated
dataset:

``` r

library(HowMaHiCo)

annot <- read_annot(system.file("extdata", "sim_fragpipe_dda_annotation.csv",
                                package = "HowMaHiCo"))
annot
#>   Condition BioReplicate TechReplicate    Sample Sample_ID Sample_folder
#> 1      CTRL    CTRL_bio1             1  CTRL_1_1  CTRL_1_1      CTRL_1_1
#> 2      CTRL    CTRL_bio2             1  CTRL_2_1  CTRL_2_1      CTRL_2_1
#> 3      CTRL    CTRL_bio3             1  CTRL_3_1  CTRL_3_1      CTRL_3_1
#> 4     TREAT   TREAT_bio1             1 TREAT_1_1 TREAT_1_1     TREAT_1_1
#> 5     TREAT   TREAT_bio2             1 TREAT_2_1 TREAT_2_1     TREAT_2_1
#> 6     TREAT   TREAT_bio3             1 TREAT_3_1 TREAT_3_1     TREAT_3_1
#>   Sample_fp Source_file Sample_peaks
#> 1  CTRL_1_1    CTRL_1_1     CTRL_1_1
#> 2  CTRL_2_1    CTRL_2_1     CTRL_2_1
#> 3  CTRL_3_1    CTRL_3_1     CTRL_3_1
#> 4 TREAT_1_1   TREAT_1_1    TREAT_1_1
#> 5 TREAT_2_1   TREAT_2_1    TREAT_2_1
#> 6 TREAT_3_1   TREAT_3_1    TREAT_3_1
```

## 2. Parse once into `pep_all`

[`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
runs the loader and writes a cache. Each focused report then renders
against that cache, so the raw files are parsed once rather than once
per report.

``` r

sim_dir <- system.file("extdata", "sim_fragpipe_dda", package = "HowMaHiCo")

pep_all <- build_pep_all(
  software       = "fragpipe_dda_individual",
  folder_data    = sim_dir,
  annotation     = annot,
  shortpep_range = mhc_length_window("MHC1")   # 8-13 AA for human HLA-I
)
#> All samples were correctly matched between the input results and the annotation table
#> Warning in build_pep_all(software = "fragpipe_dda_individual", folder_data =
#> sim_dir, : for Fragpipe, the psm file is currently being used. This means that
#> FDR has not been applied at the peptide level, only at PSM level

dim(pep_all)
#> [1] 2400   43
```

One row per peptide-sample observation:

``` r

pep_all[1:5, c("Sample", "Condition", "Peptide", "Length", "Charge", "Area")]
#>     Sample Condition    Peptide Length Charge       Area
#> 1 CTRL_1_1      CTRL GLVDWGIHEV     10    + 2    97080.1
#> 2 CTRL_1_1      CTRL  LANGVRVEA      9    + 2 19799685.5
#> 3 CTRL_1_1      CTRL  DMFTIKKII      9    + 3  2284087.0
#> 4 CTRL_1_1      CTRL VVPELLAKTV     10    + 3   299219.9
#> 5 CTRL_1_1      CTRL  YAPICPDPV      9    + 1  6409289.3
```

[`mhc_length_window()`](https://davidgz1.github.io/HowMaHiCo/reference/mhc_length_window.md)
is the single source of truth for the ligand-length window — `"MHC1"`
(8–13), `"MHC1_mouse"` (7–11, murine H-2 runs shorter) or `"MHC2"`
(12–25). The subset of `pep_all` inside that window is what the reports
call *selected peptides*.

``` r

rbind(MHC1 = mhc_length_window("MHC1"),
      MHC1_mouse = mhc_length_window("MHC1_mouse"),
      MHC2 = mhc_length_window("MHC2"))
#>            [,1] [,2]
#> MHC1          8   13
#> MHC1_mouse    7   11
#> MHC2         12   25
```

## 3. Render reports

[`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md)
wraps
[`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html):
it locates the template inside the installed package and knits it in a
clean environment. One call renders one report.

``` r

report_params <- list(
  SampleSet     = "my_experiment",
  Provider      = "My Lab",          # "" prints a generic attribution
  Subset        = "dda_all",
  FolderData    = "2_data",
  FolderResults = "3_results",
  FolderFigures = "4_figures",
  Software      = "fragpipe_dda_combined",
  MHCclass      = "MHC1"
)

run_howmahico_report("01_id_counts",
                     params = c(report_params, list(PepAllSource = "cached")),
                     output_file = "01_id_counts.html")
```

The templates on offer:

| Template | What it gives you |
|----|----|
| `00_mhc_report` | All-in-one QC report; parses the raw files itself |
| `00_mhc_upsets` | Overlap / UpSet plots only |
| `01_id_counts` | ID counts, length and charge distributions, motifs, PTM profile |
| `02_overlaps` | Replicate, cross-condition and pairwise overlap |
| `03_lcms_qc` | RT / ion mobility / *m/z* distributions, Score and mass-error QC |
| `04_quant` | log2(Area) correlation between samples, Area %CV |
| `05_quality_score` | Per-sample immunopeptidomics quality score |
| `06_quant_stats` | Differential abundance between Conditions |
| `07_pepchem` | Amino-acid composition, positional motifs, GRAVY and other descriptors |
| `08_prot_all` | Source proteins: ligands per protein, and engine-reported protein values |

Each focused report gets `pep_all` via its `PepAllSource` parameter:
`"cached"` (the default — load `<Subset>_pep_all.rda`), `"rda"` (load an
explicit `PepAllFile`), or `"build"` (parse the raw output itself,
skipping step 2 entirely).

## 4. Output

Written to `<FolderResults>/<Subset>/` on every run:

- `<Subset>_pep_all.csv` — the unified peptide table
- `<Subset>_counts_pep_all_condition.csv` — identification counts per
  Condition
- `<Subset>_seq_by_condition.xlsx` — sequences per Condition
- `<Subset>_<report>_input_params.csv` — every parameter used, for
  reproducibility

`CsvSave = TRUE` adds the intermediate tables; `PlotsSave = TRUE` writes
every figure as png to `<FolderFigures>/<Subset>/`. The HTML report goes
to `output_file`.

## A tool with no built-in loader

For a tabular export HowMaHiCo does not know, describe it in a YAML
dictionary instead of writing R code:

``` r

get_dictionary_template("my_tool.yaml")     # fill in the column mapping, then:

build_pep_all("custom", folder_data = "2_data", annotation = annot,
              dictionary = "my_tool.yaml", file_rda = "2_data/pep_all.rda")
```

The dictionary maps raw column names onto the `pep_all` schema;
reference dictionaries for the three built-in engines ship in
`inst/extdata/dictionaries/`.

## Where to go next

- [`get_pipeline_script()`](https://davidgz1.github.io/HowMaHiCo/reference/get_pipeline_script.md)
  — the runnable version of this walkthrough
- [`?run_howmahico_report`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md)
  — the full parameter reference
- The project README — parameter tables, output tiers and
  troubleshooting
