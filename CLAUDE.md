# CLAUDE.md — HowMaHiCo

## What this is

An LC-immunopeptidomics (MHC/HLA peptide) **data-analysis project**: a parameterized
RMarkdown reporting pipeline that ingests LC-MS search-engine output (FragPipe, DIA-NN,
PEAKS), normalizes it into one unified long-format table (`pep_all`), and renders
self-contained interactive HTML QC reports plus csv/xlsx/png result exports.

**Mid-conversion to an R package** (work-in-progress on the `dev` branch, rollback
point tagged `pre-package-v0`): `project-style-guide.md` documents the target
R-package + Docker + Shiny distribution pattern. The package layout is now primary —
`DESCRIPTION`, `LICENSE`/`LICENSE.md`, `NAMESPACE`, `R/` (the ~40 functions migrated
from `00_functions.R`, plus the report entry point), `inst/rmarkdown/templates/` (the
two Rmds, converted to package report templates), `tests/testthat/` (hand-synthesized
fixtures + a full testthat-edition-3 suite — loaders, annotation, checks, counting,
io-export, overlap-counters, plotting smoke tests), `.github/workflows/R-CMD-check.yaml`
(Win+Ubuntu CI, green on `dev`), `man/`, `_pkgdown.yml`, `.Rbuildignore` —
`library(HowMaHiCo)` (or `devtools::load_all()`) gives you everything; `source()`-ing
files from `0_code/` is no longer part of the workflow. `devtools::check()` is clean
(0 errors/0 warnings) as of the Phase-5 doc/check pass.
The original `0_code/`-based files (`00_functions.R`, `01_report_main_template.Rmd`,
`02_report_upsets.Rmd`, `00_knit_reports.R`, `00_extract_sample_info_fragpipe.R`)
still sit in the repo as the pre-migration reference copies — not deleted yet
(Docker/Shiny/`.bat` distribution tiers remain — Phases 7-9 of the conversion plan —
now that Phase 5's tests/CI have landed), but no longer the canonical source: treat
`R/`/`inst/` as authoritative and `0_code/` as legacy/about-to-be-removed (the
"Directory layout"/"Key files" tables below still document that legacy
`0_code/`-based layout — rendering and the function library have already moved on,
per "Pipeline / data flow" and "How to run" below; those two tables get a wholesale
rewrite once `0_code/` itself is deleted in a later phase). RStudio project file:
`HowMaHiCo.Rproj`.
Tracked in a private GitHub repo (`DavidGZ1/HowMaHiCo`, remote `origin`); `2_data/`,
`3_results/`, `4_figures/`, and rendered `*.html` reports are gitignored (regenerated
by the pipeline, kept out of version control to keep the repo small).

One vendoring note worth knowing up front: `R/vendored-deltaprotr.R` copies
`get_dirs_index_peaks()` from the author's other package, `deltaProtR`
(github.com/DavidGZ1/deltaProtR) — verbatim-adapted, not `Imports`-declared, to avoid
taking on a GitHub-only package dependency (would need `Remotes:` everywhere:
CI/Docker/installs). It's the *only* `deltaProtR` function HowMaHiCo actually calls
(confirmed by grepping every `deltaProtR::`/bare-call site across `00_functions.R` and
both Rmds) — `library(deltaProtR)` still appears in `00_functions.R`/the Rmds/
`00_extract_sample_info_fragpipe.R` for now but is vestigial and will be deleted once
the Rmds are converted to package templates.

## Directory layout (numbered-folder convention)

| Folder | Contents |
|---|---|
| `0_code/` | All logic: shared functions, driver scripts, Rmd report templates |
| `1_documentation/` | Sample annotation CSVs (one per analysis subset) |
| `2_data/` | Raw search-engine output (FragPipe `psm.tsv`, DIA-NN `report.tsv`) + cached `*_pep_all.rda` |
| `3_results/<subset>/` | Per-subset csv + xlsx outputs (`pep_all.csv`, `counts_pep_all_condition.csv`, `seq_by_condition.xlsx`, ...) |
| `4_figures/` | Optional PNG plot exports (only when `PlotsSave = TRUE`) |
| (repo root) | Rendered reports: `01_report_main__hla1_<dda\|dia>_<all\|jy\|plasma>.html` |

## Pipeline / data flow

```
LC-MS search output (FragPipe psm.tsv, DIA-NN report.tsv, PEAKS peptide.csv)
      │   read + parse + annotate  (software-specific loaders converge on one schema,
      │   exported from the HowMaHiCo package — library(HowMaHiCo))
      ▼
pep_all  — unified long-format table, cached as <FolderData>/<suffix>pep_all.rda
      │
      ▼
inst/rmarkdown/templates/howmahico-report/skeleton/skeleton.Rmd
      │   rendered via run_howmahico_report() → self-contained interactive HTML report
      │   (ID counts, overlaps, distributions, QC sections — see below)
      ▼
<FolderResults>/<subset>/*.csv, *.xlsx, input_params.csv
      +   <FolderFigures>/<subset>/*.png (optional)
```

`howmahico-upsets` (from `02_report_upsets.Rmd`) is the secondary overlap/UpSet-only
report template, rendered the same way with `template = "howmahico-upsets"`.

## Key files

- **`0_code/00_functions.R`** — the engine. Loads all libraries and defines ~40
  functions:
  - Three **software-specific loader families** that each read one tool's raw output
    and converge on the same `pep_all` schema (selected via the `Software` param):
    - `fp_read_psm_batch` / `fp_parse_pep_all` / `fp_annotate` — FragPipe `psm.tsv`
    - `diann_read_tsv_batch` / `diann_parse_pep_all` / `diann_annotate` — DIA-NN `report.tsv`
    - `peaks_read_batch` / `read_pep_peaks` — PEAKS `peptide.csv`
  - Shared helpers: `read_annot`, `print_annot`, `check_file_exists`,
    `check_output_exists`, `count_ids`, `count_ids_condition_bylengthrange`,
    `get_charge_group`, `get_proportion_charge`, `get_mat_log2area`, `summarise_area`,
    `check_ids_global`, `list_sequences`, `count_ids_by`
  - Plotting: `plot_peplength(_dens)`, `plot_pepmass`, `plot_pepmz`, `plot_venn4`,
    `plot_upset`, `ggseqlogo_bylength`, `plot_heatmap`, `plot_pca`, `plot_corr`,
    `plot_charge_proportions`, `plot_prop_length_condition`, `plot_violin_areacv`,
    plus the shared `theme_rawr` ggplot theme and `ggsave_rawr`/`ggprint_rawr` wrappers
- **`0_code/01_report_main_template.Rmd`** (~1690 lines) — the main QC report. Section
  groups in order: total IDs (incl. decoys/contaminants) → ID counts (mean±sd, by
  length, by charge) → intra-condition replicate overlap (peptides/sequences/proteins)
  → cross-condition UpSet plots → pairwise overlap matrices → peptide size distribution
  (length/mass/m_z) → 2D ID distributions (RT × 1/k0 × m/z, "pseudochromatograms") →
  log2(Area) Pearson correlation → Area %CV violin plots → identification QC
  (Score, mass error/ppm by condition & charge) → peptide motifs (seqlogo by length) →
  PTM profile → final export block (writes csv/xlsx, optionally png)
- **`0_code/02_report_upsets.Rmd`** — secondary report focused on overlap/UpSet plots
  (same params structure, narrower scope)
- **`0_code/00_knit_reports.R`** — the driver. First derives the `_jy`/`_plasma`
  annotation CSVs by filtering the `_all` annotation on `Condition` (run once), then
  calls `rmarkdown::render()` once per subset — 6 reports total
  (`{dda,dia} × {all,jy,plasma}`)
- **`0_code/00_extract_sample_info_fragpipe.R`** — scans `2_data/` recursively for
  `psm.tsv`/`report.tsv` files and auto-generates skeleton annotation CSVs
  (`get_annot_fp`, `get_annot_diann`) into `1_documentation/sample_annotation_autogenerated_*.csv`
  — a starting point you fill in (`Condition`, `BioReplicate`, etc. start blank)

## Annotation file schema (`1_documentation/sample_annotation_*.csv`)

Required columns (checked by `read_annot`):
- `Condition`, `BioReplicate`, `TechReplicate`, `Sample` — always required
- `Sample_fp` (FragPipe/DIA-NN) or `Sample_peaks` (PEAKS) — at least one required;
  matches the data subfolder name (e.g. `fragpipe_dda_combined/JY`)
- `Source_file` — required when `mode = "combined_file"` (FragPipe combined PSM, DIA-NN);
  matches the spectrum/run name within that subfolder
- `Sample_ID` — free-text human-readable identifier

Matching key for joining annotation ↔ data: `Sample_fp` alone for
`fragpipe_dda_individual`; `Sample_fp` + `Source_file` for `combined_file` mode and
DIA-NN. `read_annot` also strips `.d`/`.raw` extensions from `Source_file` and replaces
hyphens/spaces in `Sample_peaks` with underscores (matching PEAKS' own export
behavior). **Factor order for all downstream plots/tables is taken from row order in
the CSV** (`mutate(across(where(is.character), function(x) factor(x, levels = unique(x))))`).

## The `pep_all` schema

The unified long-format table every report section consumes (one row per
peptide-sample observation). Core columns: `Condition`, `BioReplicate`,
`TechReplicate`, `Sample`, `Sample_ID`, `Accession`/`ProteinFirst`/`GeneFirst`/
`OrganismFirst`, `Peptide`/`Sequence`/`Length`/`Length_range`, `Score`,
`Area`/`Log2Area`, `PTM`, `Charge`/`Nter`/`Cter`, `RT`/`invk0`/`Mass`/`ppm`/`m_z`,
`Source_file`/`Source_File_ID`/`Precursor_Id`, `Found_By`, `PeptideID`. `pep_short` is
the subset filtered to `Length` within `[ShortPeptideLenghtMin, ShortPeptideLenghtMax]`
(8–13 AAs for HLA-I, the biologically expected MHC-I ligand length window).

`pep_all` is cached to `2_data/<suffix>pep_all.rda` (suffix = `<Subset>_` or empty) so
subsequent runs/inspection don't require re-parsing the raw search files.

## How to run

Render reports with `library(HowMaHiCo)` + `run_howmahico_report()` — a thin wrapper
around `rmarkdown::render()` that locates the installed package's report template via
`system.file()` and knits it in a fresh environment (avoids a `params`-argument /
`rmarkdown::render()`-injected-`params` name collision; see `R/run-report.R`). One
call renders one report (composable — loop it for batch runs; Docker-idiomatic "one
container run = one job"):

```r
library(HowMaHiCo)
run_howmahico_report(
  template = "howmahico-report",        # or "howmahico-upsets"
  params = list(Title = "Report: MHC1p evaluation - dda_all",
                AnnotationFile = "sample_annotation_dda_all.csv",
                FolderDocumentation = "1_documentation",
                Subset = "dda_all",
                FolderData = "2_data", FolderResults = "3_results", FolderFigures = "4_figures",
                Software = "fragpipe_dda_combined", ...),
  output_file = "01_report_main__hla1_dda_all.html"
)
```

The 6-subset batch pattern that `0_code/00_knit_reports.R` used to drive directly —
deriving the `_jy`/`_plasma` annotation CSVs, then looping `render()` over
`{dda,dia} × {all,jy,plasma}` — is preserved as a `\dontrun{}` example on
`run_howmahico_report`/`derive_filtered_annotation` (`R/run-report.R`); the latter
is the exported helper for the annotation-derivation preprocessing step
(`derive_filtered_annotation("sample_annotation_dda_all.csv", "1_documentation", "JY")`).

**Breaking change from the `0_code/`-era reports — path params are now absolute** (or
relative to the render-time working directory; no longer assumed project-root-relative,
since the template ships inside an installed package and can be rendered from
anywhere). There's also a new param, `FolderDocumentation`, that the legacy Rmds
didn't need (they hardcoded `1_documentation/`):

| Param | Purpose |
|---|---|
| `Software` | `fragpipe_dda_combined` \| `fragpipe_dda_individual` \| `diann` \| `peaks_xpro` — selects the loader branch |
| `Subset` | Subset name; becomes a filename prefix and a subfolder under `FolderResults`/`FolderFigures` |
| `FolderDocumentation` | **Absolute** (or render-time-cwd-relative) path to the folder containing `AnnotationFile` |
| `AnnotationFile` | CSV name within `FolderDocumentation` |
| `FolderData` / `FolderResults` / `FolderFigures` | **Absolute** (or render-time-cwd-relative) paths for cached `pep_all` input / csv+xlsx output / png output |
| `Instrument` | `tims_tof` \| `faims_orbi` \| `orbi` — controls ion-mobility (1/k0) handling |
| `ShortPeptideLenghtMin/Max` | Defines `pep_short` window (8–13 for HLA-I) |
| `PlotsInteractive` | TRUE = plotly widgets in HTML, FALSE = static ggplots |
| `ResultsOverwrite` | FALSE makes `check_output_exists`/`check_file_exists` abort if outputs already exist |
| `TestMode` | TRUE = load only first ~100 lines per file (fast iteration; can break correlation plots) |
| `CsvSave` / `PlotsSave` | TRUE = also export intermediary csvs / png plots |
| `TestStats` | Toggles ANOVA/t-test comparisons (currently mostly commented out in the template) |

`run_howmahico_report()` always writes `input_params.csv` (package version + render
timestamp + every param, long-format, via `write_input_params()`/`write.csv_rawr()`)
into `FolderResults`, independent of `CsvSave`/`PlotsSave` — joining `pep_all.csv`,
`counts_pep_all_condition.csv`, and `seq_by_condition.xlsx` in the "always written"
export tier (see "Export tiers" below). The report header's code-version line is now
`` `r packageVersion("HowMaHiCo")` `` — reads from `DESCRIPTION`, can't drift out of
sync with a hand-typed string.

Dependencies are declared in `DESCRIPTION` (`Imports`/`Suggests`, per
`project-style-guide.md`'s meta-package-free convention) rather than `library()`-ed
at the top of a sourced script — `deltaProtR` is no longer one of them: the one
function HowMaHiCo actually called from it (`get_dirs_index_peaks`) is vendored into
`R/vendored-deltaprotr.R`.

## Conventions & gotchas

- **`Software` drives everything downstream** — the loader branch in the Rmd's
  "Loading files" chunk dispatches on this string (`grepl("fragpipe_dda", ...)`,
  `== "diann"`, `== "peaks_xpro"`). Valid combined-vs-individual mode is inferred from
  whether `"combined"`/`"individual"` appears in the `Software` string.
- **FragPipe currently reads `psm.tsv`**, not peptide-level results — this means FDR is
  applied only at the PSM level, not the peptide level (a `warning()` documents this
  explicitly in the template; treat FragPipe peptide counts with that caveat in mind).
- **DIA-NN: `ppm` is a hardcoded dummy (`= 0`)** because DIA-NN doesn't report a
  calculated m/z to derive mass error from. `Mass` itself *is* computed (from
  `Precursor.Mz`/`Precursor.Charge` via formula — not the calibrated/observed mass the
  other loaders use); the in-template `warning()` lumps both columns together as
  "missing... dummy", which overstates the case for `Mass` — check
  `diann_parse_pep_all` directly if precision matters.
- **`Instrument` only changes loader behavior for PEAKS** (`read_pep_peaks`):
  `tims_tof` parses the `X1_k0_Range` column directly into `invk0`; `faims_orbi`/`orbi`
  repurpose Compensation Voltage (`CV`) as a stand-in ("not fully supported yet" per
  inline comments/messages). The FragPipe (`Ion_Mobility`) and DIA-NN (`IM`) loaders
  map straight to `invk0` regardless of `Instrument`.
- **Fixed — `FolderFigures`/`FolderResult` typos in the setup chunk** (a copy-paste
  slip present in BOTH legacy Rmds, that would have sent `ggsave_rawr` PNG output into
  `3_results/<subset>` instead of `4_figures/<subset>`, and referenced the nonexistent
  `params$FolderResult`): `01_report_main_template.Rmd` ~L86/L92/L98 was corrected
  first; `02_report_upsets.Rmd` ~L78/L84/L90 had the *same* bug (`FolderFigures <-
  params$FolderResults` in both branches, `check_output_exists(params$FolderResult,
  ...)`) and was caught/fixed during the Phase-4 conversion. Both
  `inst/rmarkdown/templates/*/skeleton/skeleton.Rmd` now carry the corrected pattern.
- **Overwrite guards**: `check_file_exists` / `check_output_exists` throw before
  rendering if target files already exist and `ResultsOverwrite = FALSE` — intentional,
  to prevent silently clobbering prior analysis runs.
- **Export tiers**: `pep_all.csv`, `counts_pep_all_condition.csv`, and
  `seq_by_condition.xlsx` are *always* written; everything else (per-sample log2Area
  matrices, count summaries, upset tables, PNG plots) is gated behind
  `CsvSave`/`PlotsSave`.
- **Code version** in the report header is now `` `r packageVersion("HowMaHiCo")` ``
  (was a literal "Code version: vYYYYMMDD" string in the legacy Rmds) — it tracks
  `DESCRIPTION`'s `Version` field automatically; bump that (and `CLAUDE.md`'s version
  line, per the style guide's release checklist) when the template logic changes
  meaningfully, rather than hand-editing a version string in the Rmd.
- For the longer-term packaging conventions (R package structure, Docker, Shiny app,
  CI/release process) this project is expected to follow once matured into a
  distributable tool, see `project-style-guide.md`.
