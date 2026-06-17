# CLAUDE.md — HowMaHiCo

## What this is

An LC-immunopeptidomics (MHC/HLA peptide) **data-analysis project**: a parameterized
RMarkdown reporting pipeline that ingests LC-MS search-engine output (FragPipe, DIA-NN,
PEAKS), normalizes it into one unified long-format table (`pep_all`), and renders
self-contained interactive HTML QC reports plus csv/xlsx/png result exports.

**Current version: 0.11.0** — Phases 1–6 of the package conversion are complete.
v0.11.0 added a **cross-class (MHC1↔MHC2) contamination** dimension to the quality
score: `frac_cross_class` flags MHC-II ligands co-enriched in an MHC-I pulldown
(and vice versa) by their length signature — the fraction of peptides in the
*other* class's canonical window (MHC1 8–13, MHC2 12–25) that falls outside the
current window (the internal `.cross_class_range()` is the single source of truth;
the "outside-current" qualifier handles the 12–13 AA overlap). Scored
`lower_better` at low weight (a small tail is biologically normal), `NA`/dropped
for custom length windows. New plot `plot_cross_class_length()` (per-sample length
histogram with the cross-class region highlighted) + a "Cross-class contamination"
section in the `05_quality_score` report.
v0.10.0 added a per-sample **immunopeptidomics quality score** (inspired by the
author's HowDirty contamination score, but inverted — it scores how strongly a
sample resembles a real HLA immunopeptidome). New engine `R/quality-score.R`
exports `score_sample_quality()` (per-sample composite 0–100 + traffic-light
category), `qc_metrics_by_sample()` (raw signals: length-window fidelity, 9-mer
dominance, anchor-motif clarity via `anchor_information_content()`, non-tryptic
specificity, charge plausibility, depth, mass accuracy — all from `pep_all`, no
external data, no new dependency), `score_curve()`, `quality_thresholds_default()`,
`calibrate_thresholds_from_qc()`; plus `plot_quality_heatmap()` /
`plot_quality_composite()` in `R/plots.R`. The non-tryptic signal is split:
overall C-terminal K/R fraction is a low-weight *diagnostic* (some HLA-I alleles
use K/R anchors), while the *scored* metric isolates tryptic background in the
out-of-window long-peptide tail. Thresholds use literature defaults **or** are
calibrated from samples tagged as QC controls via an optional annotation `QC`
column (`ThresholdMode = "qc_relative"`); undefined dimensions (MHC-II anchors,
DIA-NN dummy `ppm`) drop out of the weighted composite instead of penalising the
sample. New focused report `05_quality_score`
(`inst/rmarkdown/templates/05_quality_score/`) renders the score against the
cached `pep_all` like the other focused reports.
`tests/testthat/test-quality-score.R` covers `score_curve()` /
`anchor_information_content()` (pure math, no synthetic peptide data).
v0.9.0 added a **dictionary-driven unified parser** so a tabular search-engine
export from a tool with no built-in loader can be ingested by editing a YAML
dictionary (no R coding, no new loader). New `build_pep_all()` branch
`software = "custom"` (with a `dictionary` arg) runs
`read_custom_batch()` → `parse_unified()` → `annotate_unified()`. The dictionary
maps raw→`pep_all` columns, sets the `Found_By` constant, and derives the shared
recipe (`Log2Area`, `Length_range`, `Nter`/`Cter`, `PeptideID`, `Charge`
formatting); per-tool transforms (unit conversions, regex extraction, accession
splitting) are pre-clean responsibilities, not dictionary-expressible. New
exports: `read_dictionary()`, `parse_unified()` (`R/parse-unified.R`),
`read_custom_batch()`, `annotate_unified()` (`R/loaders-custom.R`),
`get_dictionary_template()` (`R/get-dictionary.R`). Reference dictionaries ship
in `inst/extdata/dictionaries/` (`custom_template.yaml` + `fragpipe.yaml` /
`diann.yaml` / `peaks.yaml`); the three built-in loaders are unchanged.
`tests/testthat/test-parse-unified.R` round-trips `parse_unified()` against the
FragPipe loader. New dependency: `yaml` (transitive via `rmarkdown`). Custom
software has no inline-parsing path in the two `00_*` reports — run
`build_pep_all("custom", dictionary=...)` once, then render the focused reports
with `PepAllSource = "cached"`.
v0.8.0 gave the four focused reports a `PepAllSource` param (`"cached"` |
`"rda"` | `"build"`, via `inst/rmarkdown/shared/setup.Rmd`) so each can load the
default cache, load an explicit `.rda` (`PepAllFile`), or self-build from raw
results via `build_pep_all()`; and added a simulated FragPipe dataset
(`inst/extdata/sim_fragpipe_dda/`, moved out of `data/`) with
`tests/testthat/test-sim-fragpipe.R` (a `build_pep_all` assertion + the first
end-to-end render test of a focused report).
v0.7.1 fixed a "Duplicate chunk label 'setup'" parse error that aborted all four
focused reports: the shared `inst/rmarkdown/shared/setup.Rmd` had a fenced r-chunk
example inside its leading HTML comment, and knitr parses chunk headers even inside
comments (re-including the file → duplicate `setup`). Comment is now prose;
`tests/testthat/test-report-templates.R` guards against it.
v0.7.0 **renumbered all report templates** (breaking: the `template=` names change):
`01_mhc_report`→`00_mhc_report`, `02_mhc_upsets`→`00_mhc_upsets`,
`03_id_counts`→`01_id_counts`, `04_overlaps`→`02_overlaps`,
`05_lcms_qc`→`03_lcms_qc`, `06_quant`→`04_quant`; and rewrote the LC-MS report's
RT/1k0/m_z section to a single looped `results='asis'` chunk (config list of
views × peptide sets) instead of eight hand-written chunks. The multi-report
framework (v0.6.0): a new exported `build_pep_all()` (`R/build-pep-all.R`)
extracts the raw-file parse/cache step, and the four focused templates each
render a slice of the all-in-one `00_mhc_report` against the cached `pep_all`
(loaded via the shared `inst/rmarkdown/shared/setup.Rmd` knitr child). Build the
cache once, then render any subset. `00_mhc_report`/`00_mhc_upsets` are the
all-in-one reports (parse the raw files themselves); v0.6.1 moved the PTM profile
into `01_id_counts` with an all-peptides variant.
v0.5.0 split two report sections by length to match the "Average +/- sd" pattern:
`plot_overlap_intra_condition()` is now a single-plot function (breaking signature:
`(df, id_col, title, shortpep_range)` — was `(pep_all, pep_short, id_col, ...)`),
and the "Overlap intra-Condition" + "Peptides identified per charge" report sections
now show All peptides / Selected peptides (`pep_short`) as separate nested tabsets.
v0.4.0 was a loader-consistency + report-robustness pass: the three loaders now share
`compute_log2area()` (zero `Area` → `NA` everywhere, previously `1` for FragPipe/DIA-NN
and `NA` for PEAKS — a user-visible behavior change), `extract_run_name()` (POSIX-safe
run-name extraction, no longer Windows-backslash-only), and `validate_pep_all()`
(core-schema guard at each parser tail) — all internal helpers in `R/utils-loaders.R`.
The `00_mhc_report` template (then named `01_mhc_report`) degrades gracefully on
partial subsets (single-Condition UpSets, no-replicate Area %CV), both all-in-one
templates gained a "Session & provenance" footer, and `00_mhc_upsets` now declares
its `DataAcquisitionNames` param.
v0.3.0 was a best-practices pass: base-package imports declared, all exports made
public (no `@keywords internal`), `NEWS.md` added, internal code unified on the
native `|>` pipe (R floor raised to 4.1.0).
`project-style-guide.md` documents the target R-package + Docker + Shiny distribution
pattern. The package layout is authoritative — `DESCRIPTION`, `LICENSE`/`LICENSE.md`,
`NAMESPACE`, `R/` (~40 functions plus the report entry point),
`inst/rmarkdown/templates/` (the two Rmd report templates),
`tests/testthat/` (hand-synthesized fixtures + a full testthat-edition-3 suite —
loaders, annotation, checks, counting, io-export, overlap-counters, plotting smoke
tests), `.github/workflows/R-CMD-check.yaml` (Win+Ubuntu CI, green), `man/`,
`_pkgdown.yml`, `.Rbuildignore` — `library(HowMaHiCo)` (or `devtools::load_all()`)
gives you everything. `devtools::check()` is clean (0 errors/0 warnings).
Docker/Shiny/`.bat` distribution tiers remain (Phases 7–9).
The original `0_code/`-based files have been moved to `example/` (gitignored) as
pre-migration reference copies — no longer canonical. RStudio project file:
`HowMaHiCo.Rproj`.
Tracked in a private GitHub repo (`DavidGZ1/HowMaHiCo`, remote `origin`); `2_data/`,
`3_results/`, `4_figures/`, `example/`, and rendered `*.html` reports are gitignored.

`R/loaders-peaks-dirs.R` holds `get_dirs_index_peaks()`, the internal helper that
indexes PEAKS export subfolders for `read_peaks_batch()`. It was originally
adapted from the author's other package `deltaProtR`
(github.com/DavidGZ1/deltaProtR) but is now native HowMaHiCo code — `deltaProtR`
is not a dependency (no `Imports`/`Remotes:` entry anywhere: CI/Docker/installs).

## Directory layout (numbered-folder convention)

| Folder | Contents |
|---|---|
| `R/` | Package source: all exported functions (~40) + internal helpers |
| `inst/rmarkdown/templates/` | `00_mhc_report/`, `00_mhc_upsets/`, and the focused `01_id_counts/`, `02_overlaps/`, `03_lcms_qc/`, `04_quant/`, `05_quality_score/` skeleton Rmds (+ shared `inst/rmarkdown/shared/setup.Rmd`) |
| `inst/extdata/dictionaries/` | YAML parser dictionaries for the `software = "custom"` path: `custom_template.yaml` (fill-in) + `fragpipe.yaml`/`diann.yaml`/`peaks.yaml` (reference) |
| `tests/testthat/` | testthat-edition-3 test suite + hand-synthesized fixtures |
| `man/` | Roxygen-generated Rd files |
| `example/` | Legacy `0_code/`, `1_documentation/` pre-migration reference copies (gitignored) |
| `2_data/` | Raw search-engine output (FragPipe `psm.tsv`, DIA-NN `report.tsv`) + cached `*_pep_all.rda` (gitignored) |
| `3_results/<subset>/` | Per-subset csv + xlsx outputs (`pep_all.csv`, `counts_pep_all_condition.csv`, `seq_by_condition.xlsx`, ...) (gitignored) |
| `4_figures/` | Optional PNG plot exports (only when `PlotsSave = TRUE`) (gitignored) |

## Pipeline / data flow

```
LC-MS search output (FragPipe psm.tsv, DIA-NN report.tsv, PEAKS peptide.csv)
      │   read + parse + annotate  (software-specific loaders converge on one schema,
      │   exported from the HowMaHiCo package — library(HowMaHiCo))
      ▼
pep_all  — unified long-format table, cached as <FolderData>/<subset>_pep_all.rda
      │
      ▼
inst/rmarkdown/templates/00_mhc_report/skeleton/skeleton.Rmd
      │   rendered via run_howmahico_report() → self-contained interactive HTML report
      │   (ID counts, overlaps, distributions, QC sections — see below)
      ▼
<FolderResults>/<subset>/*.csv, *.xlsx, input_params.csv
      +   <FolderFigures>/<subset>/*.png (optional)
```

`00_mhc_upsets` (`inst/rmarkdown/templates/00_mhc_upsets/`) is the secondary
overlap/UpSet-only report template, rendered the same way with
`template = "00_mhc_upsets"`. The focused reports (`01_id_counts`, `02_overlaps`,
`03_lcms_qc`, `04_quant`) each render one slice of `00_mhc_report` against the
cached `pep_all` (load it via `build_pep_all()` first); see the v0.6.0 framework
note above.

## Key files

- **`R/loaders-fragpipe.R`**, **`R/loaders-diann.R`**, **`R/loaders-peaks.R`** —
  software-specific loader families converging on the `pep_all` schema:
  - `read_fragpipe_batch` / `parse_fragpipe` / `annotate_fragpipe` — FragPipe `psm.tsv`
  - `read_diann_batch` / `parse_diann` / `annotate_diann` — DIA-NN `report.tsv`
  - `read_peaks_batch` / `read_peaks` — PEAKS `peptide.csv`
  - Batch readers accept `annotation = annot` to read only files listed in the
    annotation table (3-way dispatch: explicit files > annotation table > scan folder)
- **`R/annotation.R`** — `read_annot`, `print_annot`, `get_annot_fragpipe`,
  `get_annot_diann`, `get_annot_sampleid`
- **`R/checks.R`** — `check_file_exists`, `check_output_exists`, `check_ids_global`
- **`R/counting.R`**, **`R/overlap-counters.R`** — `count_ids`,
  `count_ids_condition_bylengthrange`, `count_ids_by`, `get_charge_group`,
  `get_proportion_charge`, `get_mat_log2area`, `summarise_area`, `list_sequences`,
  `count_intersect`, `count_merged`, `count_samples_patients`, `select_unique`,
  `filter_unique`
- **`R/plots.R`** — `plot_peplength_dens`, `plot_pepmass`, `plot_pepmz`,
  `plot_bp_count_length`, `plot_upset`, `plot_upset_batch`, `ggseqlogo_bylength`,
  `plot_prop_length_condition`, `plot_charge_proportions`, `plot_violin_areacv`,
  `plot_corr`, `theme_rawr`, `ggsave_rawr`, `ggprint_rawr`
- **`R/io.R`** — `write.csv_rawr`, `write_input_params`
- **`R/run-report.R`** — `run_howmahico_report`, `derive_filtered_annotation`
- **`R/get-report.R`** — `get_report_template` (copies a skeleton to the working dir)
- **`R/parse-unified.R`** — `read_dictionary()` + `parse_unified()`: the
  dictionary-driven parser for the `software = "custom"` path (rename +
  `Found_By` + shared derived recipe + `validate_pep_all` guard)
- **`R/loaders-custom.R`** — `read_custom_batch()` (generic configurable
  per-sample reader) + `annotate_unified()` (generic annotation join)
- **`R/get-dictionary.R`** — `get_dictionary_template` (copies the YAML dictionary
  template to the working dir)
- **`R/quality-score.R`** — the immunopeptidomics quality-score engine:
  `qc_metrics_by_sample()`, `anchor_information_content()`, `score_curve()`,
  `quality_thresholds_default()`, `calibrate_thresholds_from_qc()`,
  `score_sample_quality()` plus the internal `.cross_class_range()`
  (MHC1↔MHC2 cross-class window) feeding the `frac_cross_class` metric
  (consumed by the `05_quality_score` report;
  `plot_quality_heatmap()`/`plot_quality_composite()`/`plot_cross_class_length()`
  live in `R/plots.R`)
- **`R/loaders-peaks-dirs.R`** — `get_dirs_index_peaks()`, the internal PEAKS
  export-subfolder indexer used by `read_peaks_batch()` (originally adapted from
  `deltaProtR`, now native)
- **`inst/rmarkdown/templates/00_mhc_report/skeleton/skeleton.Rmd`** (~1100 lines)
  — the main QC report. Sections: total IDs (incl. decoys/contaminants) → ID counts
  (mean±sd, by length, by charge) → intra-condition replicate overlap → cross-condition
  UpSet plots → pairwise overlap matrices → peptide size distribution (length/mass/m_z)
  → 2D ID distributions (RT × 1/k0 × m/z, "pseudochromatograms") → log2(Area) Pearson
  correlation → Area %CV violin plots → identification QC (Score, ppm by condition &
  charge) → peptide motifs (seqlogo by length) → PTM profile → export block
- **`inst/rmarkdown/templates/00_mhc_upsets/skeleton/skeleton.Rmd`** — secondary
  report focused on overlap/UpSet plots (loads from cached `.rda`, same params)
- **`inst/rmarkdown/templates/{01_id_counts,02_overlaps,03_lcms_qc,04_quant,05_quality_score}/`** —
  the focused reports (`01`–`04` each a slice of `00_mhc_report`;
  `05_quality_score` is the per-sample quality-score report from
  `R/quality-score.R`), sharing `inst/rmarkdown/shared/setup.Rmd` and loading the
  `pep_all` cache from `build_pep_all()` (`R/build-pep-all.R`)

## Annotation file schema (`1_documentation/sample_annotation_*.csv`)

Required columns (checked by `read_annot`):
- `Condition`, `BioReplicate`, `TechReplicate`, `Sample` — always required
- `Sample_fp` (FragPipe/DIA-NN) or `Sample_peaks` (PEAKS) — at least one required;
  matches the data subfolder name (e.g. `fragpipe_dda_combined/JY`)
- `Source_file` — required when `mode = "combined_file"` (FragPipe combined PSM, DIA-NN);
  matches the spectrum/run name within that subfolder
- `Sample_ID` — free-text human-readable identifier
- `QC` *(optional)* — flags experiment quality-control samples (`TRUE`/`"QC"`);
  consumed by the `05_quality_score` report to mark QC samples and, with
  `ThresholdMode = "qc_relative"`, to calibrate the score thresholds. `read_annot`
  passes it through untouched (no schema change needed)

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
the subset filtered to `Length` within `[ShortPeptideLengthMin, ShortPeptideLengthMax]`
(8–13 AAs for HLA-I, the biologically expected MHC-I ligand length window).

`pep_all` is cached to `2_data/<Subset>_pep_all.rda` (or `pep_all.rda` when `Subset`
is empty) so subsequent runs/inspection don't require re-parsing the raw search files.

## How to run

Render reports with `library(HowMaHiCo)` + `run_howmahico_report()` — a thin wrapper
around `rmarkdown::render()` that locates the installed package's report template via
`system.file()` and knits it in a fresh environment (avoids a `params`-argument /
`rmarkdown::render()`-injected-`params` name collision; see `R/run-report.R`). One
call renders one report (composable — loop it for batch runs; Docker-idiomatic "one
container run = one job"):

```r
library(HowMaHiCo)

# Step 1 — auto-generate annotation skeleton, then open and fill in metadata columns
get_annot_fragpipe(dir_data = "2_data") |>
  get_annot_sampleid(file_sample_list = "1_documentation/sample_list.xlsx") |>
  write.csv(row.names = FALSE, file = "1_documentation/sample_annotation_dda_all.csv")
# → open CSV, complete Condition / BioReplicate / TechReplicate / Sample_ID, save

# Step 2 — render (title is auto-generated from SampleSet / Subset / MHCclass / date)
run_howmahico_report(
  template = "00_mhc_report",            # or "00_mhc_upsets"
  params = list(SampleSet = "MEGF_035",
                AnnotationFile = "sample_annotation_dda_all.csv",
                FolderDocumentation = "1_documentation",
                Subset = "dda_all",
                FolderData = "2_data", FolderResults = "3_results", FolderFigures = "4_figures",
                Software = "fragpipe_dda_combined",
                MHCclass = "MHC1"),       # or "MHC2" for 12-25 AA window
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
| `Software` | `fragpipe_dda_combined` \| `fragpipe_dda_individual` \| `diann` \| `peaks_xpro` \| `custom` — selects the loader branch (`custom` = dictionary-driven via `build_pep_all`) |
| `SampleSet` | Human-readable experiment name; used in the auto-generated report title |
| `Subset` | Subset name; becomes a filename prefix and a subfolder under `FolderResults`/`FolderFigures` |
| `FolderDocumentation` | **Absolute** (or render-time-cwd-relative) path to the folder containing `AnnotationFile` |
| `AnnotationFile` | CSV name within `FolderDocumentation` |
| `FolderData` / `FolderResults` / `FolderFigures` | **Absolute** (or render-time-cwd-relative) paths for cached `pep_all` input / csv+xlsx output / png output |
| `PepAllSource` | **Focused reports only** (the five `01`–`05` templates, via `inst/rmarkdown/shared/setup.Rmd`): how to obtain `pep_all` — `"cached"` (default; load `<Subset>_pep_all.rda` from `FolderData`), `"rda"` (load `PepAllFile`), or `"build"` (parse the raw search output via `build_pep_all()` and write the cache). The two `00_*` all-in-one reports ignore this (they always build / load their own way). |
| `QCColumn` / `ThresholdMode` | **`05_quality_score` only**: `QCColumn` is the annotation column flagging QC controls (default `"QC"`; empty disables QC tagging); `ThresholdMode` is `"default"` (literature thresholds) or `"qc_relative"` (calibrate from the QC samples). |
| `PepAllFile` | Explicit `.rda` path, used only when `PepAllSource = "rda"` |
| `Instrument` | `tims_tof` \| `faims_orbi` \| `orbi` — controls ion-mobility (1/k0) handling |
| `MHCclass` | `"MHC1"` (8–13 AA, default) or `"MHC2"` (12–25 AA) — sets `shortpep_range`; overrides `ShortPeptideLengthMin/Max` |
| `ShortPeptideLengthMin/Max` | Custom `pep_short` window; used only when `MHCclass` is not a recognised value |
| `ResultsOverwrite` | FALSE makes `check_output_exists`/`check_file_exists` abort if outputs already exist |
| `TestMode` | TRUE = load only first ~100 lines per file (fast iteration; can break correlation plots) |
| `CsvSave` / `PlotsSave` | TRUE = also export intermediary csvs / png plots |

`run_howmahico_report()` always writes `input_params.csv` (package version + render
timestamp + every param, long-format, via `write_input_params()`/`write.csv_rawr()`)
into `FolderResults`, independent of `CsvSave`/`PlotsSave` — joining `pep_all.csv`,
`counts_pep_all_condition.csv`, and `seq_by_condition.xlsx` in the "always written"
export tier (see "Export tiers" below). The report header's code-version line is now
`` `r packageVersion("HowMaHiCo")` `` — reads from `DESCRIPTION`, can't drift out of
sync with a hand-typed string.

Dependencies are declared in `DESCRIPTION` (`Imports`/`Suggests`, per
`project-style-guide.md`'s meta-package-free convention) rather than `library()`-ed
at the top of a sourced script — `deltaProtR` is not one of them: the one
function HowMaHiCo originally borrowed from it (`get_dirs_index_peaks`) now lives
natively in `R/loaders-peaks-dirs.R`.

## Conventions & gotchas

- **`Software` drives everything downstream** — the loader branch in the Rmd's
  "Loading files" chunk dispatches on this string (`grepl("fragpipe_dda", ...)`,
  `== "diann"`, `== "peaks_xpro"`). Valid combined-vs-individual mode is inferred from
  whether `"combined"`/`"individual"` appears in the `Software` string. The
  `"custom"` value is handled only in `build_pep_all()` (not the inline-parsing
  `00_*` reports): it dispatches on the YAML `dictionary` instead of hard-coded
  loader logic.
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
- **Code version** in the report header is `` `r packageVersion("HowMaHiCo")` `` —
  reads from `DESCRIPTION` automatically. When template logic changes meaningfully,
  bump `DESCRIPTION`'s `Version:` field, add a matching entry to `NEWS.md`
  (newest version first — pkgdown renders it as the Changelog), and update the
  "Current version" line at the top of this file.
- For the longer-term packaging conventions (R package structure, Docker, Shiny app,
  CI/release process) this project is expected to follow once matured into a
  distributable tool, see `project-style-guide.md`.
