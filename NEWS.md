# HowMaHiCo 0.11.0

* Added a **cross-class (MHC1↔MHC2) contamination** dimension to the quality
  score: `frac_cross_class` flags MHC-II ligands co-enriched in an MHC-I pulldown
  (and vice versa) via their length signature — the fraction of peptides in the
  *other* class's canonical window (MHC1 8-13, MHC2 12-25) that falls outside the
  current window (so the 12-13 AA overlap is handled cleanly). Scored
  `lower_better` at low weight (a small tail is biologically normal) and `NA`
  (dropped) for custom length windows. New internal helper `.cross_class_range()`
  is the single source of truth for the windows.
* New plot `plot_cross_class_length()`: per-sample faceted length histogram with
  the cross-class region highlighted, and a matching "Cross-class contamination"
  section + Methods bullet in the `05_quality_score` report.
* `tests/testthat/test-quality-score.R`: covers `.cross_class_range()`, the new
  `quality_thresholds_default()` row, and `frac_cross_class` on an inline fixture.

# HowMaHiCo 0.10.0

* Added a per-sample **immunopeptidomics quality score** (inspired by the
  author's HowDirty contamination score, but inverted: it scores how strongly a
  sample resembles a real HLA immunopeptidome rather than its contaminant load).
  New scoring engine in `R/quality-score.R`, all from the `pep_all` schema with
  no external data and no new dependency.
* New exports: `score_sample_quality()` (per-sample composite + traffic-light
  category), `qc_metrics_by_sample()` (raw signals: length-window fidelity,
  9-mer dominance, anchor-motif clarity, non-tryptic specificity, charge
  plausibility, depth, mass accuracy), `anchor_information_content()`,
  `score_curve()`, `quality_thresholds_default()`,
  `calibrate_thresholds_from_qc()`, plus plots `plot_quality_heatmap()` and
  `plot_quality_composite()`.
* The non-tryptic signal is deliberately low-weight and split: because some
  HLA-I alleles legitimately use K/R as a C-terminal anchor, the overall
  C-terminal K/R fraction is a low-weight diagnostic, while the scored metric
  isolates tryptic background in the out-of-window (long-peptide) tail.
* Thresholds use built-in literature defaults **or** are calibrated from samples
  tagged as experiment QC controls via an optional annotation `QC` column
  (`ThresholdMode = "qc_relative"`) — no external benchmark dataset needed.
  Undefined dimensions (e.g. MHC-II anchors, DIA-NN dummy `ppm`) drop out of the
  weighted composite rather than penalising the sample.
* New focused report template `05_quality_score`
  (`inst/rmarkdown/templates/05_quality_score/`): traffic-light overview,
  composite bar chart, per-metric breakdown and a self-documenting Methods
  section, rendered against the cached `pep_all` like the other focused reports.
* `tests/testthat/test-quality-score.R`: pure-math boundary checks of
  `score_curve()` (no synthetic peptide data required).

# HowMaHiCo 0.9.0

* Added a dictionary-driven **unified parser** so a tabular search-engine export
  from a tool HowMaHiCo has no built-in loader for can be ingested by editing a
  YAML dictionary — no R coding, no new loader. New `build_pep_all()` branch
  `software = "custom"` (with a `dictionary` argument) routes through
  `read_custom_batch()` → `parse_unified()` → `annotate_unified()`. The
  dictionary maps raw → `pep_all` columns, sets the `Found_By` constant, and
  derives the shared recipe (`Log2Area`, `Length_range`, `Nter`/`Cter`,
  `PeptideID`, `Charge` formatting); per-tool transforms (unit conversions,
  regex extraction, accession splitting) are pre-clean responsibilities, not
  expressed in the dictionary.
* New exports: `read_dictionary()`, `parse_unified()`, `read_custom_batch()`,
  `annotate_unified()`, and `get_dictionary_template()` (copies a fill-in
  template to the working dir, sibling of `get_report_template()`).
* Shipped reference dictionaries in `inst/extdata/dictionaries/`
  (`custom_template.yaml` + `fragpipe.yaml` / `diann.yaml` / `peaks.yaml`
  documenting the directly-mappable subset of each built-in loader). The three
  built-in loaders are unchanged.
* `tests/testthat/test-parse-unified.R`: asserts `parse_unified()` reproduces the
  built-in FragPipe loader on the directly-mappable columns of the simulated
  dataset, plus dictionary validation and the custom `build_pep_all()` path.
* New dependency: `yaml` (already transitive via `rmarkdown`).

# HowMaHiCo 0.8.0

* The four focused reports (`01_id_counts`, `02_overlaps`, `03_lcms_qc`,
  `04_quant`) gained a `PepAllSource` param (with `PepAllFile`) selecting how to
  obtain `pep_all`: `"cached"` (default — load the `<Subset>_pep_all.rda` cache,
  the prior behavior), `"rda"` (load an explicit `.rda`), or `"build"` (parse the
  raw search output via `build_pep_all()` and write the cache). A focused report
  can now be rendered straight from results without a separate `build_pep_all()`
  call. Backward compatible — the default reproduces the old behavior.
* Added a simulated FragPipe dataset (`inst/extdata/sim_fragpipe_dda/`, 2
  Conditions x 3 BioReplicates, generated with MaHiCoInSilico) and
  `tests/testthat/test-sim-fragpipe.R`: a `build_pep_all()` loader assertion plus
  the first end-to-end render test of a focused report (gated on
  `skip_on_cran()` / pandoc). Moving the data out of `data/` into `inst/extdata/`
  also clears the R CMD check warnings about non-R files in `data/`.

# HowMaHiCo 0.7.1

* Fixed a "Duplicate chunk label 'setup'" parse error that aborted every focused
  report (`01_id_counts`, `02_overlaps`, `03_lcms_qc`, `04_quant`). The shared
  `inst/rmarkdown/shared/setup.Rmd` had a fenced r-chunk example inside its leading
  HTML comment; knitr parses chunk headers even inside comments, so that example
  re-included the file and duplicated the `setup` chunk. The comment now describes
  the include in prose, and a regression test guards against reintroducing a chunk
  fence there. (The two all-in-one reports were unaffected.)

# HowMaHiCo 0.7.0

* **Breaking: renumbered all report templates.** The `template=` value passed to
  `run_howmahico_report()` / `get_report_template()` changes:
  `01_mhc_report` → `00_mhc_report`, `02_mhc_upsets` → `00_mhc_upsets`,
  `03_id_counts` → `01_id_counts`, `04_overlaps` → `02_overlaps`,
  `05_lcms_qc` → `03_lcms_qc`, `06_quant` → `04_quant`. The two all-in-one reports
  take the `00_` prefix; the focused reports fill `01–04`.
* The LC-MS report's "Peptide ID distribution across RT, 1/k0 and m/z" section is
  now generated by a single looped `results='asis'` chunk (a config list of the
  four views × the all/selected peptide sets) instead of eight hand-written
  chunks, matching the looped style of the motif / overlap sections.

# HowMaHiCo 0.6.1

* Moved the PTM profile from `05_lcms_qc` to `03_id_counts` (it is a general
  identification property, alongside peptide motifs), and extended it to show
  **all peptides** (`pep_all`) in addition to the selected-length peptides
  (`pep_short`), in an All / Selected tabset — matching the other dual sections.
  `05_lcms_qc` now covers only the RT/1k0/mz distributions and Score/ppm QC.

# HowMaHiCo 0.6.0

## Multi-report framework

* New exported `build_pep_all()` extracts the raw-file parsing step (the
  FragPipe / DIA-NN / PEAKS read → parse → annotate dispatch) into a standalone,
  unit-tested function that writes the `<Subset>_pep_all.rda` cache. Run it once,
  then render any of the focused reports against that cache instead of
  re-parsing the raw search files per report.
* Four new focused report templates, each a slice of the all-in-one
  `01_mhc_report`, rendered the same way via `run_howmahico_report()`:
  - `03_id_counts` — total IDs, identification counts (mean±sd, by length, by
    charge, by sample), peptide size distributions, peptide motifs.
  - `04_overlaps` — intra-Condition replicate overlap, UpSet across Conditions,
    and Condition pairwise overlap.
  - `05_lcms_qc` — RT / 1k0 / m/z distributions, Score and mass-error
    identification QC, and the PTM profile (advanced LC-MS QC).
  - `06_quant` — log2(Area) correlation and Area %CV violins.
* The focused reports share one setup fragment
  (`inst/rmarkdown/shared/setup.Rmd`, pulled in via a knitr `child`) that loads
  the cache and derives the common objects, instead of duplicating the
  boilerplate in every skeleton.
* `01_mhc_report` and `02_mhc_upsets` are unchanged — full retrocompatibility.

# HowMaHiCo 0.5.0

## Report: per-length splits for the overlap and charge sections

* `plot_overlap_intra_condition()` now returns a single replicate-overlap bar
  chart for one data frame and one ID level, instead of stacking all-vs-selected
  peptides into a two-row `ggpubr::ggarrange()`. **Breaking signature change**:
  the arguments are now `(df, id_col, title = NULL, shortpep_range)` (previously
  `(pep_all, pep_short, id_col, shortpep_range)`). The main report's "Overlap
  intra-Condition" section now presents All peptides and Selected peptides as
  separate nested tabsets (Peptides / Sequences / Proteins), matching the
  "Average +/- sd" section.
* The "Peptides identified per charge +1 to +4" section now renders a plot for
  the selected-length peptides (`pep_short`) alongside the all-peptides plot, in
  an All peptides / Selected peptides tabset. The selected-length plot is also
  written out when `PlotsSave = TRUE`.

# HowMaHiCo 0.4.0

## Loader consistency & portability

* Unified `Log2Area` zero-handling across all three loaders: a zero
  `Area`/`Intensity` now maps to `NA` everywhere. Previously FragPipe and DIA-NN
  mapped it to `1` while PEAKS mapped it to `NA`, so the same zero-area row
  behaved differently depending on the search engine. **This changes
  FragPipe/DIA-NN output for zero-area rows** — they no longer carry a fabricated
  `Log2Area = 1`. The shared logic now lives in an internal `compute_log2area()`
  helper.
* Run-name extraction (DIA-NN `File.Name`, Bruker HyStar `Result.Path`) is now
  separator-agnostic via an internal `extract_run_name()` helper, replacing a
  backslash-anchored regex that only worked on Windows-style paths. The loaders
  are now portable to Linux/macOS (and Docker).
* Each `parse_*()` validates its output against the core `pep_all` schema
  (`validate_pep_all()`), so a loader that drops/renames a core column or returns
  an empty table fails loudly at the source instead of producing a half-broken
  report several sections later.

## Report robustness & provenance

* The main report (`01_mhc_report`) no longer aborts on partial subsets: the
  UpSet sections skip gracefully when fewer than two Conditions are present, and
  the Area %CV sections render an explanatory note instead of erroring when no
  replicates exist.
* Both report templates gained a "Session & provenance" footer: the run
  parameters as a table, the package version, and a collapsible `sessionInfo()`,
  so a saved HTML is self-documenting.
* Declared the previously-undeclared `DataAcquisitionNames` parameter in the
  `02_mhc_upsets` template (it was referenced in the header but never defined in
  the YAML, so it rendered blank).

# HowMaHiCo 0.3.0

## Packaging & best-practices cleanup

* Declared the previously-undeclared base-package dependencies (`grDevices`,
  `graphics`, `stats`, `utils`) in `DESCRIPTION` `Imports`.
* The full exported function set is now part of the public reference: removed
  `@keywords internal` from every exported function (the package-overview page
  and the non-exported helpers stay internal), and listed every export
  in `_pkgdown.yml`.
* All package R code — both the `R/` source and the two report templates
  (`inst/rmarkdown/templates/*/skeleton/skeleton.Rmd`) — now uses the native R
  pipe (`|>`) throughout instead of magrittr `%>%`. **This raises the minimum R
  version to 4.1.0** (`Depends: R (>= 4.1.0)`).
* De-vendored `get_dirs_index_peaks()`: the helper (originally adapted from
  `deltaProtR`) is now native HowMaHiCo code in `R/loaders-peaks-dirs.R`
  (was `R/vendored-deltaprotr.R`).
* Added this `NEWS.md` changelog.

## Bug fixes

* `check_file_exists()` now names the conflicting file in its error/warning
  message (the filename was previously printed after `stop()`, so it never
  appeared).
* `check_output_exists()` no longer lists `upset_table_prot.csv` twice.
* The log2(Area) heatmap "saved in" message now reports the actual output path
  instead of a hardcoded `4_figures/...` string.

# HowMaHiCo 0.2.1

* Peptide motifs (seqlogo) now shown up to length 24 (was 22).
* Identification counts "Average ± sd" split into per-length individual plots and
  nested tabsets, with all-peptides vs selected-peptides shown separately.
* "Peptide ID distribution across RT, 1/k0 and m/z" refactored out of the
  template into `plot_pseudochromatogram()` and `plot_2d_distribution()`.
* Replaced hardcoded `scale_y_continuous()` breaks/labels with `n.breaks = 5` in
  `plot_bp_count_length()`, `plot_count_mean_sd()`, and
  `plot_overlap_intra_condition()`.
* Homogenized bar `alpha = 0.7` and added black outlines across plot functions.
* Fixed `count_ids_condition_bylengthrange()` dropping an existing `Condition`
  column before renaming.

# HowMaHiCo 0.2.0

* Completed Phases 1–6 of the conversion into a proper R package: functions moved
  into `R/`, report templates shipped under
  `inst/rmarkdown/templates/{01_mhc_report,02_mhc_upsets}/`, a testthat
  (edition 3) suite, roxygen `man/` pages, `_pkgdown.yml`, and CI (R-CMD-check +
  pkgdown).
* Added a proportion-by-length plot at the sample level to the "Total by Sample"
  section.
* `plot_peplength_hist()` density normalized by condition total rather than
  per-group.

# HowMaHiCo 0.1.4

* Fixed rendered `output_file` landing in the installed package library instead
  of the working directory.

# HowMaHiCo 0.1.3

* Named all report chunks and unified `fig.width = 8` across chunks.
* Added `plot_peplength_hist()` (a simpler length-distribution histogram without
  the boxplot overlay, facetable, two-color by `MHCclass`, density or absolute).

# HowMaHiCo 0.1.2

* Introduced `theme_howmahico()` and applied it across plot functions and report
  skeletons.
* `MHCclass` parameter with default length windows (MHC1: 8–13 AA, MHC2:
  12–25 AA) and a manual color/fill palette per class.
* Added a pre-flight check that every file named in the annotation table exists,
  a per-sample "Total by Sample" section, and a programmatically generated report
  title.

# HowMaHiCo 0.1.1

* Suppressed the progress bar in `get_annot_diann()`.

# HowMaHiCo 0.1.0

* First package-shaped release. Renamed the report templates to `01_mhc_report`
  and `02_mhc_upsets`; split `read_peaks_batch()` into read/parse/annotate
  matching the FragPipe/DIA-NN loader families; batch readers now read only the
  files referenced in the annotation table.
