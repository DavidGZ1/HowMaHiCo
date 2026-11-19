# HowMaHiCo

A parameterized RMarkdown reporting workflow for **LC-immunopeptidomics** (MHC/HLA
peptide) data analysis. It ingests LC-MS search-engine output from multiple tools
(FragPipe, DIA-NN, PEAKS), normalizes it into a single unified long-format table
(`pep_all`), and renders self-contained, interactive HTML QC reports plus csv/xlsx
result exports.

**Distributed as an R package.** `library(HowMaHiCo)` gives you the full
function library and all ten report templates. See `project-style-guide.md` for
the longer-term R-package + Docker + Shiny distribution pattern.

## Quickstart

```r
remotes::install_github("DavidGZ1/HowMaHiCo")

HowMaHiCo::get_pipeline_script("howmahico_pipeline.R")
```

Open that script and source it. It starts in demo mode, so it runs the whole
pipeline against a small simulated dataset shipped with the package — no data of
your own required. Then set `RUN_DEMO <- FALSE`, edit the `CONFIG` block at the
top, and re-run. `vignette("howmahico")` narrates the same walkthrough.

## What it does

```
LC-MS search output (FragPipe psm.tsv, DIA-NN report.tsv, PEAKS peptide.csv)
      │   read + parse + annotate  (software-specific loaders converge on one schema)
      ▼
pep_all  — unified long-format peptide table
      │
      ▼
inst/rmarkdown/templates/00_mhc_report/skeleton/skeleton.Rmd
      │   rendered via run_howmahico_report() — self-contained interactive HTML
      │   (ID counts, replicate/condition overlaps, size & charge distributions,
      │    RT/ion-mobility/m_z "pseudochromatograms", Area correlation & %CV,
      │    Score/ppm QC, sequence motifs, PTM profile)
      ▼
csv / xlsx result tables  +  optional PNG figure exports
```

Each report is rendered once per analysis subset (e.g. acquisition mode × sample
group), driven by an annotation CSV that maps raw data files to experimental
conditions and replicates.

## Repository layout

| Folder | Contents |
|---|---|
| `R/` | Package source — 100+ exported functions (loaders, annotation, counting, statistics, plotting, export) plus the `run_howmahico_report()`/`derive_filtered_annotation()` entry points |
| `inst/rmarkdown/templates/` | The parameterized Rmd report templates — `00_mhc_report` (all-in-one), `00_mhc_upsets`, and the focused `01_id_counts`/`02_overlaps`/`03_lcms_qc`/`04_quant`/`05_quality_score`/`06_quant_stats`/`07_pepchem`/`08_prot_all`/`09_overview` — packaged for `rmarkdown::draft()`/`run_howmahico_report()`. Shared setup for the focused reports lives in `inst/rmarkdown/shared/setup.Rmd` |
| `inst/scripts/` | The guided pipeline script handed out by `get_pipeline_script()` |
| `vignettes/` | `vignette("howmahico")` — the narrated walkthrough |
| `tests/testthat/` | testthat-edition-3 suite (hand-synthesized fixtures — never derived from real instrument data) |
| `man/` | Generated roxygen2 documentation (`.Rd`) |
| `example/` | Legacy pre-package reference copies — gitignored, for reference only |

The numbered folders `1_documentation/`, `2_data/`, `3_results/`, `4_figures/`
are the **convention for your own analysis project**, not part of this
repository — they are what the `Folder*` parameters point at by default. Create
them wherever you keep the data; the package does not care where they live, and
any absolute path works.

## Requirements

- **R >= 4.1.0** (the package uses the native `|>` pipe)
- **pandoc**, to render the HTML reports. Bundled with
  [RStudio](https://posit.co/download/rstudio-desktop/); install it separately if
  you work outside RStudio. RStudio itself is optional (the repo does ship an
  `HowMaHiCo.Rproj` if you use it)
- All dependencies are declared in `DESCRIPTION` and resolved automatically — no
  manual library list, no companion-package install
- **Optional:** [limma](https://bioconductor.org/packages/limma) for the
  advanced-quantification report (`BiocManager::install("limma")`). Without it
  that report falls back to a Welch t-test automatically

## How to run

**1. Install the package**

```r
# from a local clone:
devtools::load_all()
# or from GitHub:
devtools::install_github("DavidGZ1/HowMaHiCo")
library(HowMaHiCo)
```

**2. Auto-generate an annotation CSV skeleton**

```r
# FragPipe (psm.tsv layout)
get_annot_fragpipe(dir_data = "2_data") |>
  write.csv(row.names = FALSE, file = "1_documentation/sample_annotation.csv")

# DIA-NN (report.tsv layout)
get_annot_diann(dir_data = "2_data") |>
  write.csv(row.names = FALSE, file = "1_documentation/sample_annotation_diann.csv")

# PEAKS (export folders)
get_annot_peaks(dir_data = "2_data/peaks_export") |>
  write.csv(row.names = FALSE, file = "1_documentation/sample_annotation_peaks.csv")
```

These scan `2_data` and write one row per data file — no `sample_list.xlsx`
needed to get started (`Sample_ID` can be filled in next, by hand or optionally
from a HyStar sample list).

**3. Complete the annotation CSV**

Open the generated CSV and fill in the experimental metadata:
`Condition`, `BioReplicate`, `TechReplicate`, `Sample_ID`. Verify that
`Sample_folder` matches the data subfolder names exactly, then save. The column
is the same for every search engine; tables from older runs that use the
engine-specific `Sample_fp` (FragPipe/DIA-NN) or `Sample_peaks` (PEAKS) still
load unchanged.

> **Two things the annotation table controls:**
> - **Inclusion** — only samples listed in the annotation table are read and
>   reported. Any sample present in the results folder but missing from the table
>   is silently excluded, so the table is also how you subset a run.
> - **Ordering** — Conditions, replicates and samples appear in every plot and
>   table in the **row order of the annotation CSV**. Order the rows the way you
>   want them displayed (factor levels are taken from first appearance).

*(Optional)* `Sample_ID` can be populated automatically from a Bruker HyStar
sample list with `get_annot_sampleid()` instead of typing it by hand:

```r
read.csv("1_documentation/sample_annotation.csv") |>
  get_annot_sampleid(file_sample_list = "1_documentation/sample_list.xlsx") |>
  write.csv(row.names = FALSE, file = "1_documentation/sample_annotation.csv")
```

`get_annot_sampleid()` joins on `Source_file`, so both sides must use the same
run naming. It warns when nothing matched (showing example values from each
side) and when only some rows matched (naming the dropped ones); pass
`keep_all = TRUE` to keep every annotation row instead, with the unmatched
`Sample_ID` left empty.

**4. (Optional) Get a local copy of the report template to customise**

```r
get_report_template("MyReport", template = "00_mhc_report")
```

**5. Render a report**

**Edit these for your run** (the rest can stay at the example defaults):

- `SampleSet` / `Subset` — experiment name and subset label (used in the title,
  filenames, and output subfolders)
- `FolderDocumentation` / `FolderData` / `FolderResults` / `FolderFigures` —
  absolute (or render-time-cwd-relative) paths
- `AnnotationFile` — the CSV filled in above
- `Software` — `fragpipe_dda_combined` | `fragpipe_dda_individual` | `diann` |
  `peaks_xpro` | `custom`
- `Instrument` — `tims_tof` | `faims_orbi` | `orbi`
- `MHCclass` — `MHC1` (human, 8–13 AA), `MHC1_mouse` (murine H-2, 7–11 AA) or `MHC2` (12–25 AA)
- `Provider` — your lab or platform, printed in the report header; leave empty
  for a generic attribution
- `output_file` — the HTML filename to write

The full parameter reference is in the [Parameters](#parameters) section below.

```r
run_howmahico_report(
  template = "00_mhc_report",          # or "00_mhc_upsets"
  params = list(
    SampleSet        = "project_id",
    Provider         = "My Lab",      # "" prints a generic attribution
    DataAnalysisNames = "analyst",
    WetLabNames      = "operator",
    FolderDocumentation = "1_documentation",
    AnnotationFile   = "sample_annotation.csv",
    Subset           = "dda_all",
    FolderData       = "2_data",
    FolderResults    = "3_results",
    FolderFigures    = "4_figures",
    # ProjectDir     = getwd(),   # set if rendering from a subdirectory
    Instrument       = "tims_tof",    # faims_orbi | orbi
    Software         = "fragpipe_dda_combined",
    MHCclass         = "MHC1",        # MHC1 (8-13 AA) | MHC1_mouse (7-11 AA) | MHC2 (12-25 AA)
    TestMode         = FALSE,
    ResultsOverwrite = TRUE,
    PlotsSave        = FALSE,
    CsvSave          = FALSE
  ),
  output_file = "01_report_main__hla1_dda_all.html"
)
```

`FolderDocumentation`/`FolderData`/`FolderResults`/`FolderFigures` are absolute
(or render-time-working-directory-relative) paths — the template ships inside an
installed package and can be rendered from anywhere. One call renders one report;
loop with `derive_filtered_annotation()` for multi-subset batch runs (see the
`\dontrun{}` example on `run_howmahico_report`).

**Focused reports (instead of the all-in-one `00_mhc_report`)** — build the
`pep_all` cache once with `build_pep_all()`, then render any subset of the
smaller, purpose-focused templates against it (no re-parsing per report):

```r
annot <- read_annot("1_documentation/sample_annotation.csv")
build_pep_all(software = "fragpipe_dda_combined", folder_data = "2_data",
              annotation = annot, shortpep_range = c(8, 13),
              file_rda = "2_data/dda_all_pep_all.rda")

for (tmpl in c("01_id_counts",     # ID counts, size distributions, motifs, PTM
               "02_overlaps",      # replicate / condition / pairwise overlap
               "03_lcms_qc",       # RT/1k0/mz, Score/ppm (advanced)
               "04_quant",         # log2(Area) correlation, Area %CV
               "05_quality_score", # per-sample immunopeptidomics quality score
               "06_quant_stats",   # differential abundance between Conditions
               "07_pepchem",       # amino-acid composition, motifs, GRAVY & co.
               "08_prot_all",      # source proteins, ligands per protein
               "09_overview")) {   # one-page overview: counts, lengths, score, red flags
  run_howmahico_report(tmpl,
                       params = list(SampleSet = "project_id", Subset = "dda_all",
                                     FolderData = "2_data", FolderResults = "3_results",
                                     FolderFigures = "4_figures",
                                     Software = "fragpipe_dda_combined"),
                       output_file = paste0(tmpl, "__dda_all.html"))
}
```

Each focused report chooses how to obtain `pep_all` via the `PepAllSource` param:
`"cached"` (default — load the `<Subset>_pep_all.rda` cache), `"rda"` (load an
explicit `PepAllFile`), or `"build"` (parse the raw search output itself, no
separate `build_pep_all()` call). So to render a single focused report directly
from results, pass `PepAllSource = "build"` (plus `Software`, `AnnotationFile`,
`FolderDocumentation`) and skip the `build_pep_all()` step above.

`00_mhc_report` (all-in-one) and `00_mhc_upsets` are unchanged and still parse
the raw files themselves.

`06_quant_stats` compares peptide `Area` between Conditions (normalization, data
completeness, PCA and clustered/unclustered heatmaps, then per-pair differential
abundance with volcano plots and a presence/absence track for condition-exclusive
ligands). It uses [limma](https://bioconductor.org/packages/limma), an optional
Bioconductor dependency — install it with `BiocManager::install("limma")`, or
render with `StatMethod = "ttest"` (and `NormMethod = "median"`) for a
Bioconductor-free run; the report falls back to that automatically when limma is
missing. Its methods and their justification are documented in the report itself.

Reports are written to `output_file` (HTML), and result tables/figures are written
under `<FolderResults>/<subset>/` and `<FolderFigures>/<subset>/`.

## The reports

| Template | What it gives you | Needs |
|---|---|---|
| `00_mhc_report` | All-in-one QC report: ID counts, overlaps, size/charge distributions, RT–ion-mobility–*m/z* distributions, Area correlation and %CV, Score/ppm QC, motifs, PTM profile | raw files (parses them itself) |
| `00_mhc_upsets` | Overlap / UpSet plots only | `pep_all` cache |
| `01_id_counts` | Identification counts (mean ± sd per Condition / BioReplicate / Sample), length and charge distributions, sequence motifs, PTM profile | cache |
| `02_overlaps` | Intra-Condition replicate overlap (counts and %), cross-Condition UpSet, pairwise overlap matrices | cache |
| `03_lcms_qc` | RT / ion-mobility / *m/z* distributions, pseudochromatograms and pseudomobilograms, Score and mass-error QC | cache |
| `04_quant` | log2(Area) Pearson correlation between samples, Area %CV violins | cache |
| `05_quality_score` | Per-sample immunopeptidomics quality score (0–100) with a traffic-light overview and per-metric breakdown | cache |
| `06_quant_stats` | Differential abundance between Conditions: normalization, completeness, PCA, heatmaps, volcano/MA, plus a presence/absence track for condition-exclusive ligands | cache; limma optional |
| `07_pepchem` | Amino-acid composition, per-position residue frequency, and descriptors (GRAVY, pI, charge, …) compared between Conditions | cache |
| `08_prot_all` | Protein level: source proteins per sample, ligands per protein, top source proteins, detection breadth, and any protein-level values the search engine reported | cache |
| `09_overview` | **Start here.** One-page overview for the biologist: ligands per sample, whether the lengths look like MHC ligands, the quality score, and a plain-language list of red flags, with pointers to the focused report for each topic | cache |

The focused reports each render one slice of the analysis and are
independent — render only the ones you need. `00_mhc_report` covers most of
`01`–`04` in a single document.

## Parameters

Every template accepts the common set; each report adds its own. All parameters
are written to `<report>_input_params.csv` on every run, so a report always
records how it was produced.

### Common to every report

| Param | Purpose |
|---|---|
| `SampleSet` | Experiment name, used in the auto-generated report title |
| `Provider` | Organisation/person that produced the report, printed in the header. Empty (default) prints a generic attribution |
| `Subset` | Subset label — becomes a filename prefix and a subfolder under `FolderResults`/`FolderFigures` |
| `DataAnalysisNames` / `WetLabNames` | Free-text credits shown in the header |
| `FolderDocumentation` | Folder containing `AnnotationFile` |
| `AnnotationFile` | Annotation CSV name within `FolderDocumentation` |
| `FolderData` | Raw search output, and where the `pep_all` cache is read/written |
| `FolderResults` / `FolderFigures` | csv+xlsx output / png output |
| `ProjectDir` | Project root; relative folder paths resolve from here. Set it when rendering from a subdirectory |
| `Software` | `fragpipe_dda_combined` \| `fragpipe_dda_individual` \| `diann` \| `peaks_xpro` \| `custom` — selects the loader |
| `Instrument` | `tims_tof` \| `faims_orbi` \| `orbi` — only affects PEAKS ion-mobility parsing |
| `MHCclass` | `MHC1` (human, 8–13 AA) \| `MHC1_mouse` (murine H-2, 7–11 AA) \| `MHC2` (12–25 AA). Overrides `ShortPeptideLength*` |
| `ShortPeptideLengthMin` / `Max` | Custom length window, used only when `MHCclass` is not one of the three above |
| `TestMode` | `TRUE` keeps ~100 rows **per run** — a fast dry run that preserves every run/Condition/replicate |
| `ResultsOverwrite` | `FALSE` aborts rather than overwriting results from an earlier run |
| `CsvSave` / `PlotsSave` | Also write the intermediate csv tables / every figure as png |
| `InteractivePlots` | `TRUE` renders the convertible plots as interactive plotly widgets (hover, zoom, pan) instead of static images. Applies to the plots printed from ordinary chunks; plots inside tabset loops, the sequence logos, the UpSet plots and the ggpubr composites stay static, and the log2(Area) correlation matrices are interactive either way |

Folder paths are absolute, or relative to the working directory you render from
— the templates live inside the installed package and can be rendered from
anywhere.

### Focused reports only

| Param | Purpose |
|---|---|
| `PepAllSource` | How to obtain `pep_all`: `"cached"` (default — load `<Subset>_pep_all.rda`), `"rda"` (load `PepAllFile`), or `"build"` (parse the raw output itself, skipping `build_pep_all()`) |
| `PepAllFile` | Explicit `.rda` path, used only with `PepAllSource = "rda"` |

### `05_quality_score`

| Param | Purpose |
|---|---|
| `QCColumn` | Annotation column flagging QC control samples (default `"QC"`; empty disables) |
| `ThresholdMode` | `"default"` (literature thresholds) or `"qc_relative"` (calibrate from the QC samples) |

### `06_quant_stats`

| Param | Purpose |
|---|---|
| `PeptideSet` | `"selected"` (the MHC length window) or `"all"` |
| `QuantFeature` / `QuantUnit` | Matrix rows (`Peptide` \| `Sequence` \| `PeptideID` \| `ProteinFirst`) and columns (`BioReplicate` \| `Sample` \| `Condition`) |
| `MinReplicates` | A feature is tested when quantified in ≥ this many units of ≥ 1 Condition |
| `NormMethod` | `median` \| `quantile` \| `cyclicloess` \| `scale` \| `none` |
| `ImputeMethod` | `none` \| `minprob` \| `mindet` |
| `StatMethod` | `limma` (moderated t) or `ttest` (Welch — no Bioconductor dependency) |
| `BlockVar` | Optional column for `limma::duplicateCorrelation` |
| `FdrCutoff` / `Log2FcCutoff` | Significance cut-offs |
| `MinDetectExclusive` | Detection count required to call a feature condition-exclusive |
| `TopNHeatmap` / `PermutationTest` | Heatmap feature count; whether to run the PERMANOVA test |

### `07_pepchem`

| Param | Purpose |
|---|---|
| `PeptideSet` | `"selected"` or `"all"` |
| `PropertySet` | `core` (Length, GRAVY, pI, Charge) or `extended` (+ MW, Boman, hydrophobic moment, instability/aliphatic index, AA class fractions) |
| `MotifLength` | Length used for the per-position frequency map: `"auto"` (modal) or an integer |
| `TerminalPositions` | Comma-separated positions profiled across all lengths; negative counts from the C-terminus |
| `ChargePh` | pH for the net-charge descriptor |
| `MinPeptidesSample` | Samples with fewer unique sequences are flagged as unreliable |
| `FdrCutoff` | BH significance cut-off |

## Output

Written on **every** run, to `<FolderResults>/<Subset>/`:

| File | Contents |
|---|---|
| `<Subset>_pep_all.csv` | The unified peptide table |
| `<Subset>_counts_pep_all_condition.csv` | Identification counts per Condition |
| `<Subset>_seq_by_condition.xlsx` | Peptide sequences per Condition |
| `<Subset>_<report>_input_params.csv` | Every parameter used, plus package version and timestamp |

Plus each report's own result tables (`quant_stats_results.csv`,
`pepchem_summary.csv`, …). `CsvSave = TRUE` adds the intermediate tables
(per-sample log2Area matrices, count summaries, upset tables);
`PlotsSave = TRUE` writes every figure as png to `<FolderFigures>/<Subset>/`.
The HTML report itself goes to `output_file`.

`build_pep_all()` also writes the `<Subset>_pep_all.rda` cache into
`FolderData`, which is what the focused reports read.

## Comparing runs

One render scores one subset. To compare several — two experiments, the
subsets of one, or the same QC standard measured week after week — stack the
`<Subset>_scores.csv` tables that `05_quality_score` writes:

```r
runs <- compare_runs(c(jy     = "3_results/dda_jy",       # results folders,
                       plasma = "3_results/dda_plasma"))  # csv paths, or data frames
summarise_runs(runs)                  # per-run median / IQR + Pass/Warning/Fail counts
plot_run_trend(runs)                  # one panel per metric, runs on the x axis

# longitudinal view of a QC standard, in render order
compare_runs(list.dirs("3_results/qc", recursive = FALSE), order = "timestamp") |>
  plot_run_trend(type = "line")
```

`compare_runs()` reads the companion `*_05_quality_score_input_params.csv` to
label each run (`SampleSet | Subset`) and to record its `MHCclass`,
`ThresholdMode` and render time. It warns when runs were scored with different
`MHCclass` or `ThresholdMode`, because their composite scores are then not
directly comparable.

## Glossary

The reports distinguish **peptides** (distinct peptidoforms - one sequence with
two modifications counts twice) from **sequences** (stripped, counted once) and
**parent proteins** (protein *groups* for DIA-NN and PEAKS). *Selected* peptides
are those inside the expected ligand length window for the run (`MHCclass`).

Columns of `pep_all` / `pep_all.csv`, one row per peptide-sample observation.
The same table is printed in every report, both generated from
`pep_all_glossary()`:

| Column | Meaning | Notes |
|---|---|---|
| `Condition` | Experimental group the sample belongs to | From the annotation table; factor order = annotation row order |
| `BioReplicate` | Biological replicate within a Condition | From the annotation table |
| `TechReplicate` | Technical/injection replicate within a BioReplicate | From the annotation table |
| `Sample` | The analysed sample - the unit most plots are drawn per | From the annotation table |
| `Sample_ID` | Free-text human-readable sample identifier | Optional; get_annot_sampleid() can fill it from a HyStar sample list |
| `Accession` | Protein accession(s) the peptide was assigned to | A protein GROUP for DIA-NN (';'-list) and PEAKS (':'-list); a single `sp\|ID\|ENTRY` string for FragPipe |
| `ProteinFirst` | Leading protein of the group | Default protein key of build_prot_all() |
| `GeneFirst` | Leading gene name of the group | Empty when the engine reports no gene |
| `OrganismFirst` | Organism suffix parsed from the leading accession |  |
| `Peptide` | Peptide as reported, modifications included | Two peptidoforms of one sequence are two different peptides |
| `Sequence` | Stripped amino-acid sequence, no modifications | The 'sequences' counted in Venn/UpSet plots |
| `Length` | Number of amino acids in Sequence |  |
| `Length_range` | Whether Length falls in the expected ligand window | Window from MHCclass (or ShortPeptideLengthMin/Max); defines pep_short |
| `Score` | Search-engine confidence score | Engine-specific and NOT comparable across engines: FragPipe hyperscore, DIA-NN Q.Value (lower is better), PEAKS -10lgP |
| `Area` | Precursor peak area (linear scale) | NA when the engine reported zero - see compute_log2area() |
| `Log2Area` | log2 of Area | NA for zero/absent Area in every loader |
| `PTM` | Modification token(s) as the engine wrote them | UniMod accessions for DIA-NN, delta masses for FragPipe/PEAKS; translate_ptm() maps both to names at plot time |
| `Charge` | Precursor charge state, formatted '+ n' |  |
| `Nter` | First residue of Sequence |  |
| `Cter` | Last residue of Sequence | C-terminal K/R fraction is a tryptic-background diagnostic in the quality score |
| `RT` | Retention time | Minutes, as reported by the engine |
| `invk0` | Ion mobility, 1/k0 | timsTOF only; FAIMS compensation voltage is substituted for faims_orbi |
| `Mass` | Precursor mass | Observed/calibrated for FragPipe and PEAKS; COMPUTED from Precursor.Mz and charge for DIA-NN |
| `ppm` | Mass error in parts per million | A hardcoded dummy 0 for DIA-NN, which reports no observed precursor m/z; dropped from the quality score there |
| `m_z` | Precursor mass-to-charge ratio | The library value for DIA-NN |
| `Source_file` | Raw file / run the observation came from | Extracted by extract_run_name() |
| `Source_File_ID` | Engine's own run identifier |  |
| `Precursor_Id` | Engine's precursor identifier | DIA-NN |
| `Found_By` | Search engine that produced the row | 'FragPipe', 'DIA-NN', 'PEAKS', or the dictionary's value for custom input |
| `PeptideID` | Composite peptide identifier used for joins and counting |  |

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `render params not declared in YAML: X` | The template has no parameter `X`. Check the tables above — report-specific params only exist on their own report |
| `pep_all cache not found at ...` | No `build_pep_all()` run yet for this `Subset`. Either run it, or render with `PepAllSource = "build"` |
| `The following result files were found and they cannot be overwritten` | Results from an earlier run are in the way. Move them, or set `ResultsOverwrite = TRUE` |
| `Files listed in the annotation table were not found` | `FolderData` or the `Sample_folder` column does not match the data layout |
| A sample is missing from the report | It is not listed in the annotation table — only listed samples are read |
| `This step needs the 'limma' package` | `BiocManager::install("limma")`, or render `06_quant_stats` with `StatMethod = "ttest"` and `NormMethod = "median"` |
| Only one Condition, and comparison sections are empty | Expected — pairwise sections need ≥ 2 Conditions and say so rather than failing |
| Plots or correlations look wrong after a quick run | `TestMode = TRUE` keeps ~100 rows per run; correlations need the full data |
| `pandoc` errors when rendering | pandoc is missing or not on `PATH`. Use RStudio, or install pandoc separately |

## More detail

- `vignette("howmahico")` — the narrated walkthrough
- `get_pipeline_script()` — the runnable version of it
- `?run_howmahico_report`, `?build_pep_all` and the
  [function reference](https://davidgz1.github.io/HowMaHiCo/reference/)
- `CLAUDE.md` — pipeline internals, the `pep_all` schema and known gotchas
  (maintainer-facing)
- `project-style-guide.md` — the longer-term R-package/Docker/Shiny distribution
  pattern this project is expected to graduate into

## License

HowMaHiCo is free software, licensed under the **GNU General Public License,
version 2 or (at your option) any later version** — `GPL (>= 2)`, the same terms
R itself uses (see `LICENSE.md`). This choice is dictated by the dependencies:
`Peptides`, `gplots` and `ggcorrplot` are GPL-2 only, `ggupset` is GPL-3 and
`limma` is GPL (>= 2), so a permissive licence such as MIT could not describe the
installed work, and a GPL-3-only one would be incompatible with the GPL-2-only
packages. "GPL-2 or later" is compatible with each of them.
