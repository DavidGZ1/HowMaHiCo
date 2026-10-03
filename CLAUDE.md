# CLAUDE.md — HowMaHiCo

## What this is

An LC-immunopeptidomics (MHC/HLA peptide) **data-analysis project**: a parameterized
RMarkdown reporting pipeline that ingests LC-MS search-engine output (FragPipe, DIA-NN,
PEAKS), normalizes it into one unified long-format table (`pep_all`), and renders
self-contained interactive HTML QC reports plus csv/xlsx/png result exports.

**Current version: 0.21.0** — Phases 1–6 of the package conversion are complete.
v0.21.0 is **Tier C stage 3**: the **`InteractivePlots`** param, declared by all
ten templates. `ggprint_rawr()` gained an `interactive` argument that returns
`plotly::ggplotly(input)` — keeping its caller-frame name resolution and its
not-generated guard — and the shared setup (plus the two `00_*` templates, which
have their own) derives `interactive_plots <- isTRUE(params$InteractivePlots)`,
passed at the **34 call sites that print from ordinary chunks**. Plots inside
`results='asis'` tabset loops are deliberately untouched: an htmlwidget printed
from such a loop needs an explicit `tagList`/`knit_print` dance and otherwise
renders **empty with no error** (the same reason those loops use `kable` instead
of `DT`), and a test now guards that boundary. Unconvertible classes
(`.ggplotly_incompatible`: ggpubr composites, seqlogos, objects already widgets)
are returned unchanged rather than erroring, so asking for interactivity can
never break a report. The three bare plot prints in `05_quality_score` and the
four `ggplotly()` calls on the correlation matrices now route through the same
helper — the latter with `interactive = TRUE` hardcoded, preserving their
always-interactive behaviour. Verified by rendering: a new test in
`test-sim-fragpipe.R` renders `05_quality_score` with the toggle on and off and
asserts the widget containers *and* the embedded plotly library are present in
one and absent in the other — the only way to catch the silent-empty-widget
failure.
v0.20.0 is **Tier C stage 2**: the two holes the quality score had in the
abstract's headline claims. (a) **MHC class II had no motif dimension at all** —
`frac_9mer` and `anchor_information` are both `NA` there (no fixed-length anchor
register) — so the new metric **`frac_nested_core`** (internal
`.nested_core_fraction()`) measures the fraction of in-window ligands sharing a
**9-mer** (the MHC-II binding-core length) with another ligand of the same
sample: class-II peptides come as ragged, length-variable families around one
core, which no alignment, register guess or predictor is needed to see.
`quality_thresholds_default("MHC2")` gives it the anchor metric's weight (3) and
the label "Nested-core families"; for MHC-I it is a **weight-0 diagnostic**.
Metric keys stay identical across classes. (b) **Mass error cannot exist for
DIA-NN** — `Precursor.Mz` is the *library* value and `report.tsv` carries no
observed precursor m/z, so the dummy `ppm` cannot be repaired; instead
**`median_abs_rt_error`** and **`median_abs_im_error`** (|`RT` −
`Predicted.RT`|, |`invk0` − `Predicted.IM`|, via the internal
`.median_abs_delta()`) score DIA calibration accuracy from columns
`parse_diann()` already carried into `pep_all` and nothing used. They are `NA`
for FragPipe/PEAKS, dropping out of the composite exactly as `ppm` does for
DIA-NN, and an all-zero difference returns `NA` so a placeholder column cannot
score as perfect. Both substitutions are documented in `05_quality_score`'s
Methods section.
v0.19.0 is the first stage of the **Tier C** worklist in `plans_dgz.md` (the
gap list between the code and `example/abstract_eupa2026_v3.md`): **readable PTM
names + one generated glossary**, display/docs only. New `R/ptm.R` exports
`ptm_reference()` and `translate_ptm()`, which map all three engine dialects of
the `PTM` column onto one name — DIA-NN's UniMod accessions (`(UniMod:35)`),
FragPipe's position-prefixed delta mass (`2M(15.9949)`) and PEAKS' 2-decimal
bracketed delta mass (`[+15.99]`) all become `Oxidation`. **A UniMod-only
translation would have been a silent no-op on the project's default FragPipe
data**, which is why both forms are handled. `plot_ptm_heatmap()` gained
`translate = TRUE` (+ a `reference` pass-through), applied after the existing
token-splitting line so both the count and proportion branches inherit it;
unmatched tokens pass through **unchanged** rather than becoming `NA`, and
`ptm_reference()` is ordered by commonness because a few modifications are
mass-degenerate (`Glu->pyro-Glu`/`Dehydrated`) and the first row within
tolerance wins. The wrong note in `00_mhc_report`/`01_id_counts` ("Fragpipe and
DIA-NN … UniMode PTM codes") is corrected. Also new: **`pep_all_glossary()`**
(`R/report-helpers.R`), 30 rows documenting the core schema *with* its
misreadable parts (DIA-NN dummy `ppm`, computed-not-observed `Mass`,
`Accession`-as-group, engine-specific `Score`), rendered by the new shared child
**`inst/rmarkdown/shared/glossary.Rmd`** in all ten templates and reproduced in
the README — replacing `00_mhc_report`'s hardcoded prose, which had gone stale
(it claimed a 12–20 AA MHC-II window; the real window is 12–25).
v0.18.0 added the **protein-level table and report** (`R/prot-all.R` +
`08_prot_all`): `build_prot_all()` condenses `pep_all` to one row per (protein,
`Sample`) — ligands contributed, summed `Area` (linear-scale sum then log2, as
`build_quant_matrix()` does, **not** the `Log2Area` average that
`get_mat_log2area()` uses), unique-peptide counts from the previously unused
`Is_Unique`/`Proteotypic` flags, and the protein annotation. The protein key is a
param (`ProteinFeature`: `ProteinFirst` default \| `GeneFirst` \| `Accession`)
because `Accession` is a protein *group* only for DIA-NN and PEAKS; and
`MultiMapping` (`leading` default \| `all`) chooses how a ligand that maps to
several proteins is counted, with `expand_mapped_proteins()` resolving the
engine-specific mapped-protein column via `Found_By`. **Engine-reported
protein-level values are carried through**: `prot_engine_columns()` finds DIA-NN's
`PG.*`/`Genes.*` quantities and q-values (already in `pep_all`, previously
unused) and `build_prot_all()` carries them by a unique-within-group rule that
returns `NA` rather than averaging when a value genuinely varies;
`plot_ligand_vs_protein_quant()` compares them against the summed ligand
intensity. `parse_diann()`'s protein-column selection moved to
`dplyr::any_of(diann_protein_columns())` so a report using either DIA-NN naming
generation (`PG.Quantity` vs `PG.Abundance`) keeps its quantities instead of
having them silently dropped — or aborting the parse. Descriptive only: no
differential testing (use `06_quant_stats` with `QuantFeature = "ProteinFirst"`)
and no length normalisation, which needs the FASTA (see *Deferred designs*).
**Note the protein count here need not match `01_id_counts`**, which counts
`n_distinct(Accession)`; the report says so explicitly.
v0.17.0 is a **distributability pass**: the report header attribution is no longer
hardcoded. Every skeleton branded its output to one platform ("provided by the
Immunopeptidomics Platform (IPP)", plus a personal `@dkfz.de` address and a
`**Code author:** DGZ` line in the two `00_*` reports); all nine templates now
declare an optional **`Provider`** param and render the line through the new
exported `provider_line()` (`R/report-helpers.R`), which falls back to a generic
sentence naming no organisation when `Provider` is empty. Called namespaced
(`` `r HowMaHiCo::provider_line(params$Provider)` ``) because in the two `00_*`
templates the header sits *above* their inline setup chunk, so the package is not
attached yet. Also new: **`inst/scripts/howmahico_pipeline.R`** + the exported
**`get_pipeline_script()`** (a sibling of `get_report_template()` /
`get_dictionary_template()`) — a runnable, commented walkthrough that renders via
`run_howmahico_report()` rather than by opening a template, and that starts in a
**demo mode** running end-to-end against `inst/extdata/sim_fragpipe_dda` with no
user data; and the package's first **vignette** (`vignettes/howmahico.Rmd`,
`VignetteBuilder: knitr`), which gives the pkgdown site an Articles tab. The
README was corrected and expanded — its headline example passed a `Title` param
no template declares, and `rmarkdown` **errors** on undeclared params, so the
primary documented entry point failed on copy-paste.
v0.16.1 fixed the **pkgdown site build**, which had failed on every `master` push
since v0.8.0: pkgdown aborts when an exported function is missing from the
`_pkgdown.yml` reference index, and v0.9.0–v0.13.0 added 15 exports without
indexing them. `devtools::check()` never reads `_pkgdown.yml` and the pkgdown
workflow only runs on `master`, so the break was only visible after a merge —
`tests/testthat/test-pkgdown-index.R` now guards it in the ordinary suite
(exports ⊆ index, no stale entries, no duplicates; it walks up to find the
`.Rbuildignore`d `_pkgdown.yml` and skips when no source tree is reachable).
v0.16.0 added the **peptide-chemistry report `07_pepchem`** and its engine
`R/pepchem.R` — the first part of HowMaHiCo that describes what the ligands are
*made of* rather than which they are. `pepchem_by_sample()` reduces `pep_all` to
its distinct `Sequence` per `Sample` and attaches the descriptors from
`peptide_properties()` (`GRAVY`, `pI`, `Charge`, `MW`, `Boman`,
`HydrophobicMoment`, `InstabilityIndex`, `AliphaticIndex` + `frac_*` amino-acid
class fractions), computed **once over the unique sequences**; `aa_composition()`
and `aa_position_frequency()` give the position-independent and per-position
residue tables (the latter generalises `anchor_information_content()`, and the
two now share `.aa_alphabet()` / `.resolve_positions()`).
**The unit of analysis is the sample, not the peptide**: `summarise_pepchem()`
collapses each sample to one value per descriptor, `aggregate_pepchem()` gives
the per-Condition mean ± sd across samples, and `compare_pepchem(level =
"sample")` tests across samples (Kruskal-Wallis + pairwise Wilcoxon, BH within a
contrast, `MedianDiff` + the new scale-free `cliffs_delta()`). That test is
deliberately low-powered — on 3 vs 3 samples a two-sided Wilcoxon cannot reach
p < 0.1, the same structural limit `06_quant_stats` documents for its Fisher
track — so `level = "peptide"` is reported alongside as an explicitly
pseudo-replicated, descriptive track. `compare_aa_frequency()` applies the same
machinery per residue to per-sample frequencies (**not** a chi-square on pooled
residue counts, which would treat every residue as an independent draw). New
plots in `R/plots.R`: `plot_aa_composition()` (bar / heatmap / log2 enrichment
vs. the pooled composition), `plot_aa_position_heatmap()`,
`plot_property_distribution()`, `plot_property_sample_summary()`,
`plot_property_effectsize()`. **New dependency `Peptides`** (CRAN, GPL-2, Rcpp
only) in `Imports` — vectorised and the canonical GRAVY implementation, so the
scales are not re-derived; `Peptides::aaComp()` is *not* used (per-sequence list)
and its per-descriptor "unrecognized amino acid types" warnings are consolidated
into one. Peptide **position within the parent protein** was deferred — see
*Deferred designs* below.
**Two silent-failure fixes found while verifying it**: (a) `ggsave_rawr()` /
`ggprint_rawr()` resolved the plot name with a bare `exists()`, which searches
from the *helper's own* frame outwards (namespace → `globalenv()`) and never
reaches a report's knit env (`new.env(parent = globalenv())`) — so
`PlotsSave = TRUE` wrote **no** png in any report and `ggprint_rawr()` returned
the warning string instead of the plot, swallowed by `warning = FALSE` chunks.
The name is now resolved in the caller's frame via the shared internal
`.plot_was_built()` (`R/theme-and-save.R`), and a non-symbol argument
(`plots[[nm]]`, the export-loop idiom) is judged by value so a `NULL` plot is
skipped; (b) `05_quality_score` had **never rendered** — an inline `` `r ...` ``
expression ended in a bare comma-separated string list instead of a `paste0()`
call, a syntax error caught only at inline-parse time, and no test rendered that
template. Both are guarded by new tests.
v0.15.0 was a robustness + schema pass driven by `plans_dgz.md`.
**Mouse MHC-I**: `MHCclass` accepts **`"MHC1_mouse"`** (7–11 AAs) next to `MHC1`
(8–13) and `MHC2` (12–25); the windows/palettes now come from
`mhc_length_window()` / `mhc_class_palette()` in the new **`R/report-helpers.R`**
instead of three copy-pasted lists in the skeletons plus a fourth inside
`.cross_class_range()`. The quality score follows: for mouse, `frac_9mer` counts
**8- and 9-mers** (H-2Kb favours 8-mers, H-2Db 9-mers) with the label
"8/9-mer fraction" and higher cut-offs (`quality_thresholds_default()` gained an
`mhcclass` arg), and the anchor motif is scored on whichever of the two lengths
dominates — metric *keys* unchanged.
**Three abort/silent-failure fixes**: (a) a single-Condition subset no longer
kills every report — `combn(conditions, 2)` is replaced by the exported
`condition_pairs()` (empty list for one Condition, `self = TRUE` for the overlap
matrix diagonal); (b) an all-zero-`Area` dataset no longer aborts —
`get_mat_log2area()` returns a `0 x n` matrix with a warning and the correlation
chunks test for it *before* `cor()` (which errors with `'x' is empty`); (c)
`get_annot_sampleid()` warns when nothing/only some of the annotation matched the
HyStar sample list and gained `keep_all = TRUE` (left join).
**`TestMode` rebuilt**: files are read in full and reduced to ~100 rows **per
run** (`subsample_testmode()` in `R/utils-loaders.R`) instead of the first 100
lines of the file — for a combined FragPipe `psm.tsv` the old behaviour kept only
the first run and broke the annotation join.
**One annotation format for every engine**: `read_annot()` accepts a canonical
**`Sample_folder`** column and derives `Sample_fp` (verbatim) and `Sample_peaks`
(PEAKS-normalized) from it, so the loaders are untouched and legacy CSVs still
load; `get_annot_fragpipe()`/`get_annot_diann()` emit `Sample_folder`, and PEAKS
gained **`get_annot_peaks()`**.
v0.14.0 added the **advanced-quantification report `06_quant_stats`** and its engine
`R/quant-stats.R` — the first part of HowMaHiCo that *compares* conditions rather
than describing them. `build_quant_matrix()` collapses `pep_all` into a
feature × unit log2 matrix (`Area` summed over precursors on the linear scale,
technical replicates averaged into their `BioReplicate`), then
`filter_quant()` → `normalize_quant()` → `impute_quant()` →
`test_differential()` (limma `~ 0 + Condition` with pairwise contrasts and
`eBayes(trend = TRUE, robust = TRUE)`, or a dependency-free Welch `"ttest"`) →
`test_detection()` (Fisher exact on detection counts) →
`combine_quant_results()` / `summarise_significant()`, plus
`permanova_condition()` (base-R Anderson-2001 pseudo-F permutation test).
**Missing values run on two tracks**: the quantitative test on observed (or
imputed) values, and a presence/absence track for condition-exclusive ligands
whose fold change is undefined — flagged by a *detection-count* rule, not an FDR
cut-off, because a 3-vs-3 Fisher test cannot go below p = 0.1. **`limma` is a
`Suggests` dependency**, guarded by the internal `.require_limma()`; the report
falls back to `StatMethod = "ttest"` / `NormMethod = "median"` automatically when
it is absent. New plots in `R/plots.R`: `plot_completeness()`,
`plot_missing_heatmap()`, `plot_intensity_dist()`, `plot_dynamic_range()`,
`plot_pca()`, `plot_quant_heatmap()` (clustered/unclustered ggplot2 tile map —
`plot_heatmap()` writes a png and cannot be printed in a tabset),
`plot_volcano()`, `plot_ma()`, `plot_pvalue_hist()`, `plot_sig_summary()`. The
report carries its own "Methods & justification" section. Also fixed:
`run_howmahico_report("05_quality_score")` was unreachable (documented but absent
from the `match.arg` choices) — `05` and `06` are now registered and
`test-report-templates.R` guards that every shipped template directory is
offered.
v0.13.0 was a plots/exports pass driven by `plans_dgz.md`: `plot_pseudochromatogram()`
now fills RT bars by peptide count (density gradient) instead of per-Condition
colour; new `plot_pseudomobilogram()` (count vs `invk0`, configurable `binwidth`,
default 0.2) was added next to it and wired into `03_lcms_qc` (new
"Pseudomobilograms" tab in the RT/1k0/mz view config) and `00_mhc_report`;
`plot_charge_proportions()` bars gained a black outline; the peptide-motif window
was extended to **7–25 AAs** (`01_id_counts`/`00_mhc_report`, was capped at 24);
and a **subset prefix** is now applied to every result filename via a shared
`result_prefix` (`= Subset`, `NULL` when unset) passed to `write.csv_rawr()` /
`write_input_params()` and the `seq_by_condition.xlsx` write (e.g.
`dda_all_pep_all.csv`; `input_params` combines subset + report name to avoid
collisions). The "implement safeguard when some conditions/replicates give 0
areas" item was moved to standby (no repro).
v0.12.0 was a focused-report polish pass (no new engines): `01_id_counts` gained an
**Average +/- sd per BioReplicate** section mirroring the per-Condition one
(`plot_count_mean_sd()` gained a `group_var` arg, default `"Condition"`); its
**Proportion by length** content was pulled into its own 2nd-level section with
Condition / BioReplicate / Sample tabs (previously nested under the Total-by
sections). `02_overlaps` gained an **Overlap intra-Condition (%)** section
(`plot_overlap_intra_condition()` gained a `value` arg, `"count"`/`"percent"`).
Across the focused templates, "Selected peptides" headers now show the active
length window (e.g. "(8 to 13 AAs)") via `shortpep_range`, and the "Proteins"
ID-level **headers/labels** were renamed to "Parent proteins" — display only: the
data keys (`counts_levels`, `n_Proteins` columns, `count_lim$Level`) and plot axis
labels are unchanged (a separate `counts_labels` display vector backs the renamed
headers). The InteractivePlots/ggplotly toggle remains on the to-do list.
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
`NAMESPACE`, `R/` (100+ exported functions plus the report entry point),
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
| `R/` | Package source: all exported functions (100+) + internal helpers |
| `inst/rmarkdown/templates/` | `00_mhc_report/`, `00_mhc_upsets/`, and the focused `01_id_counts/`, `02_overlaps/`, `03_lcms_qc/`, `04_quant/`, `05_quality_score/`, `06_quant_stats/`, `07_pepchem/`, `08_prot_all/` skeleton Rmds (+ the shared children `inst/rmarkdown/shared/setup.Rmd` and `glossary.Rmd`) |
| `inst/scripts/` | `howmahico_pipeline.R` — the guided, runnable walkthrough handed out by `get_pipeline_script()` |
| `vignettes/` | `howmahico.Rmd` — the narrated walkthrough (`vignette("howmahico")`) |
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
- **`R/get-pipeline-script.R`** — `get_pipeline_script` (copies
  `inst/scripts/howmahico_pipeline.R` to the working dir; same
  `system.file()` → exists-guard → `file.copy()` shape as
  `get_dictionary_template`)
- **`R/quality-score.R`** — the immunopeptidomics quality-score engine:
  `qc_metrics_by_sample()`, `anchor_information_content()`, `score_curve()`,
  `quality_thresholds_default()`, `calibrate_thresholds_from_qc()`,
  `score_sample_quality()` plus the internals `.cross_class_range()`
  (MHC1↔MHC2 cross-class window) feeding the `frac_cross_class` metric,
  `.nested_core_fraction()` (the class-II motif dimension behind
  `frac_nested_core`) and `.median_abs_delta()` (the DIA RT/IM calibration
  metrics)
  (consumed by the `05_quality_score` report;
  `plot_quality_heatmap()`/`plot_quality_composite()`/`plot_cross_class_length()`
  live in `R/plots.R`)
- **`R/quant-stats.R`** — the advanced-quantification engine behind
  `06_quant_stats`: `build_quant_matrix()`, `filter_quant()`,
  `normalize_quant()`, `impute_quant()`, `test_differential()`,
  `test_detection()`, `combine_quant_results()`, `summarise_significant()`,
  `permanova_condition()` plus the internal `.require_limma()` /
  `.pairwise_contrasts()`. `limma` is a `Suggests` dependency; the
  `method = "ttest"` / `NormMethod = "median"` path needs no Bioconductor
  package. Its plots (`plot_completeness()`, `plot_missing_heatmap()`,
  `plot_intensity_dist()`, `plot_dynamic_range()`, `plot_pca()`,
  `plot_quant_heatmap()`, `plot_volcano()`, `plot_ma()`, `plot_pvalue_hist()`,
  `plot_sig_summary()`) live in `R/plots.R`
- **`R/pepchem.R`** — the peptide-chemistry engine behind `07_pepchem`:
  `peptide_properties()` (per-**unique**-sequence descriptors via `Peptides`),
  `pepchem_properties()` (the `core`/`extended` PropertySet lists),
  `aa_composition()`, `aa_position_frequency()` (per-position residue table;
  negative positions count from the C-terminus), `pepchem_by_sample()`,
  `summarise_pepchem()` → `aggregate_pepchem()` (the two-step per-sample →
  per-Condition aggregation), `cliffs_delta()`, `compare_pepchem()` and
  `compare_aa_frequency()`, plus the internal `.aa_alphabet()` /
  `.resolve_positions()` (shared with `anchor_information_content()`),
  `.aa_classes()`, `.residue_counts()` and the `.compare_groups()` test
  scaffold. Its plots (`plot_aa_composition()`, `plot_aa_position_heatmap()`,
  `plot_property_distribution()`, `plot_property_sample_summary()`,
  `plot_property_effectsize()`) live in `R/plots.R`
- **`R/prot-all.R`** — the protein-level engine behind `08_prot_all`:
  `build_prot_all()` (one row per protein x Sample), `summarise_prot_all()`,
  `top_source_proteins()`, `expand_mapped_proteins()` (engine-specific
  mapped-protein column, dispatched on `Found_By`), `prot_engine_columns()` and
  `diann_protein_columns()` (the shared registry `parse_diann()`'s `any_of()`
  also uses), plus internals `.mapped_protein_column()`,
  `.unique_peptide_flag()` and `.unique_or_na()`. Its plots
  (`plot_proteins_per_sample()`, `plot_peptides_per_protein()`,
  `plot_top_proteins()`, `plot_protein_detection()`,
  `plot_ligand_vs_protein_quant()`) live in `R/plots.R`
- **`R/ptm.R`** — `ptm_reference()` (curated UniMod accession / name /
  monoisotopic delta-mass table, ordered by commonness so the first match within
  tolerance wins on mass-degenerate pairs) + `translate_ptm()` (vectorised over
  the unique tokens; reads the payload inside `()`/`[]`, dispatches on
  UniMod-accession vs signed-decimal, returns unmatched tokens unchanged).
  Consumed by `plot_ptm_heatmap(translate = TRUE)`; `pep_all$PTM` stays raw
- **`R/report-helpers.R`** — the settings the templates derive from their params:
  `mhc_length_window()` (MHC1 8–13 / MHC1_mouse 7–11 / MHC2 12–25, else the
  `ShortPeptideLength*` params), `mhc_class_palette()`, `mhc_classes()` and
  `condition_pairs()` (all pairwise Condition comparisons; empty list for a single
  Condition, `self = TRUE` adds the diagonal). Single source of truth — the
  skeletons and `R/quality-score.R`/`R/quant-stats.R` all call these. Also
  `pep_all_glossary()`, the single source of the schema documentation rendered by
  `inst/rmarkdown/shared/glossary.Rmd` and copied into the README
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
- **`inst/rmarkdown/templates/{01_id_counts,02_overlaps,03_lcms_qc,04_quant,05_quality_score,06_quant_stats,07_pepchem}/`** —
  the focused reports (`01`–`04` each a slice of `00_mhc_report`;
  `05_quality_score` is the per-sample quality-score report from
  `R/quality-score.R`; `06_quant_stats` is the advanced-quantification /
  differential-abundance report from `R/quant-stats.R`; `07_pepchem` is the
  peptide-physicochemical-properties report from `R/pepchem.R`), sharing
  `inst/rmarkdown/shared/setup.Rmd` and loading the `pep_all` cache from
  `build_pep_all()` (`R/build-pep-all.R`)

## Annotation file schema (`1_documentation/sample_annotation_*.csv`)

Required columns (checked by `read_annot`):
- `Condition`, `BioReplicate`, `TechReplicate`, `Sample` — always required
- `Sample_folder` — the data subfolder name (e.g. `fragpipe_dda_combined/JY`),
  **the same column whatever the search engine**. The engine-specific legacy names
  `Sample_fp` (FragPipe/DIA-NN) and `Sample_peaks` (PEAKS) are still accepted; at
  least one of the three is required. `read_annot()` derives the missing ones:
  `Sample_fp` is a verbatim copy of `Sample_folder`, `Sample_peaks` a copy with
  PEAKS' hyphen/space normalization — so the loaders, which key on
  `Sample_fp`/`Sample_peaks`, are unchanged. A user-supplied alias is never
  overwritten
- `Source_file` — required when `mode = "combined_file"` (FragPipe combined PSM, DIA-NN);
  matches the spectrum/run name within that subfolder
- `Sample_ID` — free-text human-readable identifier
- `QC` *(optional)* — flags experiment quality-control samples (`TRUE`/`"QC"`);
  consumed by the `05_quality_score` report to mark QC samples and, with
  `ThresholdMode = "qc_relative"`, to calibrate the score thresholds. `read_annot`
  passes it through untouched (no schema change needed)

`get_annot_fragpipe()` / `get_annot_diann()` / `get_annot_peaks()` generate the
skeleton table (with `Sample_folder`) for their respective exports.

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
| `PepAllSource` | **Focused reports only** (the seven `01`–`07` templates, via `inst/rmarkdown/shared/setup.Rmd`): how to obtain `pep_all` — `"cached"` (default; load `<Subset>_pep_all.rda` from `FolderData`), `"rda"` (load `PepAllFile`), or `"build"` (parse the raw search output via `build_pep_all()` and write the cache). The two `00_*` all-in-one reports ignore this (they always build / load their own way). |
| `PeptideSet` / `QuantFeature` / `QuantUnit` / `MinReplicates` / `NormMethod` / `ImputeMethod` / `StatMethod` / `BlockVar` / `FdrCutoff` / `Log2FcCutoff` / `MinDetectExclusive` / `TopNHeatmap` / `PermutationTest` | **`06_quant_stats` only**: which peptides to analyse (`"selected"` = `pep_short`, or `"all"`), the matrix rows (`Peptide` default \| `Sequence` \| `PeptideID` \| `ProteinFirst`) and columns (`BioReplicate` default \| `Sample` \| `Condition`), the filtering cut-off (default 2 units in ≥1 Condition), normalization (`median` default \| `quantile` \| `cyclicloess` \| `scale` \| `none`), imputation (`none` default \| `minprob` \| `mindet`), test (`limma` default \| `ttest`), an optional `limma::duplicateCorrelation` blocking column, the significance cut-offs, the detection-count rule for condition-exclusive features, the heatmap feature count, and whether to run the PERMANOVA permutation test. |
| `PeptideSet` / `PropertySet` / `MotifLength` / `TerminalPositions` / `ChargePh` / `MinPeptidesSample` / `FdrCutoff` | **`07_pepchem` only**: which peptides to analyse (`"selected"` = `pep_short`, or `"all"`), the descriptor set (`core` = Length/GRAVY/pI/Charge \| `extended` adds MW, Boman, hydrophobic moment, instability + aliphatic index and the `frac_*` class fractions — see `pepchem_properties()`), the peptide length used for the per-position frequency map (`"auto"` = modal length, or an integer), the comma-separated positions profiled across all lengths (negative counts from the C-terminus), the pH of the net-charge descriptor, the unique-sequence count below which a sample is flagged as noisy, and the BH significance cut-off. |
| `Provider` | Organisation/person that produced the report, printed in the header via `provider_line()`. Default `""` prints a generic attribution naming no organisation. Declared by all nine templates. |
| `PeptideSet` / `ProteinFeature` / `MultiMapping` / `TopNProteins` / `MinPeptidesProtein` | **`08_prot_all` only**: which peptides to condense, the protein grouping column (`ProteinFirst` default \| `GeneFirst` \| `Accession`), how a multi-mapping ligand is counted (`leading` default \| `all`), and the size/threshold of the source-protein ranking. |
| `QCColumn` / `ThresholdMode` | **`05_quality_score` only**: `QCColumn` is the annotation column flagging QC controls (default `"QC"`; empty disables QC tagging); `ThresholdMode` is `"default"` (literature thresholds) or `"qc_relative"` (calibrate from the QC samples). |
| `PepAllFile` | Explicit `.rda` path, used only when `PepAllSource = "rda"` |
| `Instrument` | `tims_tof` \| `faims_orbi` \| `orbi` — controls ion-mobility (1/k0) handling |
| `MHCclass` | `"MHC1"` (human, 8–13 AA, default), `"MHC1_mouse"` (murine H-2, 7–11 AA) or `"MHC2"` (12–25 AA) — sets `shortpep_range` and the palette via `mhc_length_window()`/`mhc_class_palette()`; overrides `ShortPeptideLengthMin/Max` |
| `ShortPeptideLengthMin/Max` | Custom `pep_short` window; used only when `MHCclass` is not a recognised value |
| `ResultsOverwrite` | FALSE makes `check_output_exists`/`check_file_exists` abort if outputs already exist |
| `TestMode` | TRUE = keep only the first ~100 rows **per run** (fast iteration on a representative subset — every run/Condition/replicate survives, unlike a head-of-file truncation of a combined export; can still break correlation plots) |
| `CsvSave` / `PlotsSave` | TRUE = also export intermediary csvs / png plots |
| `InteractivePlots` | TRUE = the plots printed from **ordinary chunks** become plotly widgets via `ggprint_rawr(interactive = ...)`; plots inside `results='asis'` tabset loops stay static (a widget printed from such a loop silently renders empty), as do the unconvertible classes in `.ggplotly_incompatible` (ggpubr composites, seqlogos, `plot_heatmap()`'s base graphics). The two log2(Area) correlation matrices pass `interactive = TRUE` unconditionally - they have been widgets since v0.1 |

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

## Deferred designs

Work that was planned in detail, then parked. Kept here (rather than only as a
one-line `plans_dgz.md` standby entry) so it can be resumed without re-deriving
the investigation.

### Peptide position within the parent protein (deferred v0.16.0)

The third part of the physicochemical-properties request. Out of scope of
`07_pepchem` because it is the only part needing user-supplied input beyond
`pep_all`.

- **No loader carries a position column.** FragPipe's `psm.tsv` `select()`
  whitelist (`R/loaders-fragpipe.R`) drops `Protein Start`/`Protein End`;
  DIA-NN's `report.tsv` has none at all (`RT.Start`/`RT.Stop` are *retention
  time*); PEAKS' start/end live in `protein-peptides.csv`, which the package
  never reads. The `software = "custom"` dictionary path is the one place a
  `Start` column would survive today, since `parse_unified()` imposes no
  whitelist beyond the dictionary.
- **Approach when resumed:** an optional `FastaFile` report param plus a
  ~25-line base-R FASTA reader (`read_fasta()` → `Header`, `Accession`,
  `Sequence`, `ProteinLength`; accession = field 2 of a `sp|P01234|NAME` header,
  else the first whitespace token) and `map_peptide_positions()`, joining
  `ProteinFirst` (first entry when `;`-separated) to the FASTA and locating each
  peptide with `stringr::str_locate(..., fixed(Sequence))` → `Start`, `End`,
  `RelPosition`, `DistNterm`, `DistCterm`, warning with the unmapped fraction.
  No new dependency. It would also unlock a true proteome background for the
  composition section, replacing the pooled-subset reference `07_pepchem`
  currently uses.
- **Plot:** `plot_protein_position(pos, type = c("relative", "terminal"))`, in a
  `results='asis'` section that emits its own heading only when a FASTA is given
  (the `imputation-section` pattern in `06_quant_stats`).
- **Test fixture needed:** the shipped sim data has 462 peptides over *synthetic*
  accessions (`sp|Q8R3TN|NM3_HUMAN` …) with no real protein to locate them in.
  Generate `inst/extdata/sim_fragpipe_dda_proteins.fasta` — one ~150–250 AA
  synthetic protein per `Protein ID`, each embedding its peptide(s) at a random
  offset (~80 KB against the existing 532 KB fixture dir). Leave a few
  accessions out to exercise the unmapped-fraction warning.
