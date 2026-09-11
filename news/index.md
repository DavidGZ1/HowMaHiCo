# Changelog

## HowMaHiCo 0.18.0

### Protein-level table and report

- **New `08_prot_all` report and `R/prot-all.R` engine.** Every other
  report is peptide-centric; protein information existed only as
  `n_Proteins` columns inside the ID-count tables and two protein x
  sample log2 matrices written under `CsvSave`.
  [`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md)
  now condenses `pep_all` to **one row per (protein, `Sample`)**:
  ligands contributed, summed intensity, unique-peptide counts, and the
  protein annotation. It is written to `<Subset>_prot_all.csv` on every
  run.
- `Area` is summed on the **linear** scale within a sample and log2’d
  afterwards, as
  [`build_quant_matrix()`](https://davidgz1.github.io/HowMaHiCo/reference/build_quant_matrix.md)
  does. Note the older protein matrices in `00_mhc_report`/`04_quant`
  take a different route —
  [`get_mat_log2area()`](https://davidgz1.github.io/HowMaHiCo/reference/get_mat_log2area.md)
  *averages* `Log2Area` — so those numbers are not comparable with
  these.
- **The protein key is a parameter**, because `Accession` is a protein
  *group* only for DIA-NN (a `;`-list) and PEAKS (a `:`-list) — FragPipe
  puts a single `sp|ID|ENTRY` string there. `ProteinFeature` accepts
  `ProteinFirst` (default), `GeneFirst` or `Accession`.
- **`MultiMapping` chooses how a shared ligand is counted.** A short
  non-tryptic HLA peptide often maps to several proteins and neither
  convention is right: `"leading"` (default) counts it once so
  per-protein counts still reconcile with the peptide count, `"all"`
  counts it for every candidate.
  [`expand_mapped_proteins()`](https://davidgz1.github.io/HowMaHiCo/reference/expand_mapped_proteins.md)
  resolves the engine-specific mapped-protein column (FragPipe
  `Mapped_Proteins`, DIA-NN/PEAKS `Accession`, each with its own
  separator) by dispatching on `Found_By`, and warns and falls back to
  leading when the table carries no such list.
- `n_Peptides_unique` finally uses `Is_Unique` (FragPipe) and
  `Proteotypic` (DIA-NN) — both have been carried into `pep_all` since
  the loaders were written and were never read.
- New exports:
  [`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md),
  [`summarise_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_prot_all.md),
  [`top_source_proteins()`](https://davidgz1.github.io/HowMaHiCo/reference/top_source_proteins.md),
  [`expand_mapped_proteins()`](https://davidgz1.github.io/HowMaHiCo/reference/expand_mapped_proteins.md),
  [`prot_engine_columns()`](https://davidgz1.github.io/HowMaHiCo/reference/prot_engine_columns.md),
  [`diann_protein_columns()`](https://davidgz1.github.io/HowMaHiCo/reference/diann_protein_columns.md),
  plus
  [`plot_proteins_per_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_proteins_per_sample.md),
  [`plot_peptides_per_protein()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_peptides_per_protein.md),
  [`plot_top_proteins()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_top_proteins.md),
  [`plot_protein_detection()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_protein_detection.md)
  and
  [`plot_ligand_vs_protein_quant()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_ligand_vs_protein_quant.md).

### Protein data the search engine already reported

- **DIA-NN’s protein-group quantities and q-values are now carried
  through** rather than only recomputed from peptides. `PG.MaxLFQ`,
  `PG.Quantity`, `Genes.MaxLFQ`, `PG.Q.Value` and relatives have been
  sitting in `pep_all` unused;
  [`prot_engine_columns()`](https://davidgz1.github.io/HowMaHiCo/reference/prot_engine_columns.md)
  finds whichever are present and
  [`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md)
  carries them by a **unique-within-group rule** — a value that
  genuinely varies within a group (which happens legitimately when
  grouping by `GeneFirst`) becomes `NA` and is counted in an attribute,
  never averaged or silently first-picked.
- [`plot_ligand_vs_protein_quant()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_ligand_vs_protein_quant.md)
  plots summed ligand `Area` against the engine’s own protein quantity
  with a Spearman correlation. A weak correlation is the expected
  result: HLA presentation is shaped by processing and binding, so the
  plot *shows* the report’s central caveat instead of only asserting it.
- **Fixed:
  [`parse_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_diann.md)
  could drop protein quantities, or refuse to parse at all.** Its
  `select()` was a bare-name whitelist of ~45 columns, so a report
  missing any one of them errored, and newer DIA-NN releases — which
  renamed these fields (`PG.Quantity` to `PG.Abundance`, `PG.Normalised`
  to `PG.NormalisedAbundance`) — had their protein quantities silently
  discarded before reaching `pep_all`. The protein/gene-level names now
  go through `dplyr::any_of(diann_protein_columns())`, so either naming
  generation survives.
- FragPipe’s `psm.tsv` reports no protein quantity (it lives in
  `protein.tsv`, which this package does not read) and PEAKS’ peptide
  export reports none, so the report’s search-engine section degrades to
  a note naming what does report it.

### Scope and caveats

The report is deliberately **descriptive** — no differential testing,
since `06_quant_stats` already accepts `QuantFeature = "ProteinFirst"` —
and carries a Methods section stating that summed ligand intensity is
not protein abundance, that there is no length normalisation (which
needs the search FASTA, still deferred), that protein inference is weak
for short non-tryptic peptides, and that **its protein count need not
match `01_id_counts`**, which counts `n_distinct(Accession)`.

### Also

- Fixed: `docs/` was missing from `.Rbuildignore`, so `R CMD check`
  raised a “non-standard file/directory found at top level” note for
  anyone who had built the pkgdown site locally.
- `tests/testthat/test-prot-all.R` covers the aggregation rules on
  hand-built fixtures — the shipped simulated dataset has a blank
  `Mapped Proteins` column in every row and the
  `make_diann_report_raw()` helper sets every `PG.*` column to `NA`, so
  neither multi-mapping nor the engine passthrough can be exercised
  against them. Two render tests cover `08_prot_all` end to end,
  including that `MultiMapping = "all"` degrades cleanly when nothing is
  mapped.

## HowMaHiCo 0.17.0

### Reports are no longer branded to one platform

- **New optional `Provider` report param, declared by all nine
  templates.** The header attribution used to be hardcoded into every
  skeleton (“provided by the Immunopeptidomics Platform (IPP)”), along
  with a personal `@dkfz.de` contact block and a `**Code author:** DGZ`
  line in the two `00_*` reports — so every report rendered by anyone
  was attributed to one lab. The attribution is now rendered from the
  param by the new exported
  [`provider_line()`](https://davidgz1.github.io/HowMaHiCo/reference/provider_line.md)
  (`R/report-helpers.R`), which returns a generic sentence naming no
  organisation when `Provider` is empty (the default).
- The helper is called namespaced,
  `` `r HowMaHiCo::provider_line(params$Provider)` ``: in
  `00_mhc_report` and `00_mhc_upsets` the header sits *above* their
  inline setup chunk, so the package is not attached when the inline
  expression evaluates.
- `00_mhc_upsets` gained the description and `**Code version:**` lines
  it was missing — the nine headers are now uniform for the first time.

### A runnable on-ramp

- **New `inst/scripts/howmahico_pipeline.R` + exported
  [`get_pipeline_script()`](https://davidgz1.github.io/HowMaHiCo/reference/get_pipeline_script.md)**
  — a commented walkthrough from raw search output to rendered reports,
  copied into the working directory the same way
  [`get_report_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_report_template.md)
  and
  [`get_dictionary_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dictionary_template.md)
  hand out their files. It renders through
  [`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md)
  rather than asking the reader to open a template and knit it by hand.
- It starts in **demo mode**: sourced as-is it runs the whole pipeline
  against the simulated dataset in `inst/extdata/sim_fragpipe_dda`, so a
  fresh install can be exercised before any real data is involved.
- **The package’s first vignette** (`vignettes/howmahico.Rmd`,
  `VignetteBuilder: knitr`) narrates the same walkthrough and gives the
  pkgdown site an Articles tab. Its pipeline chunks are `eval = FALSE`,
  but the
  annotation/[`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
  section really runs against the simulated data, so the article cannot
  silently rot.

### README

- **Fixed: the headline
  [`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md)
  example could not be run.** It passed `Title = ...`, which no template
  declares, and `rmarkdown` *errors* on an undeclared param
  (`"render params not declared in YAML"`) — so copy-pasting the primary
  documented entry point failed outright.
- Added a Quickstart, a table of what each of the nine reports produces,
  a full parameter reference (common, focused-only, and the per-report
  sets for `05`, `06` and `07`), an output section naming the
  always-written files and the `CsvSave`/`PlotsSave` tiers, and a
  troubleshooting table. Users are no longer sent to `CLAUDE.md`, which
  is maintainer-facing.
- Corrected stale claims: `07_pepchem` was missing from every template
  list, “mid-conversion, on the `dev` branch”, “~40 functions” (there
  are 118 exports), the numbered project folders presented as repository
  contents, and RStudio listed as a requirement rather than pandoc.

### Guards

- `test-report-templates.R` now checks that **every** shipped template
  declares the common param set, and that no template hardcodes an
  organisation, author or contact address. A param added to eight of
  nine templates is not a soft failure: `render()` stops outright when a
  caller passes a param the template does not declare.
- `test-get-pipeline-script.R` covers the copy/overwrite behaviour,
  [`parse()`](https://rdrr.io/r/base/parse.html)s the shipped script so
  it cannot rot into a syntax error, and asserts every template name it
  mentions is still offered by
  [`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md).
- `test-sim-fragpipe.R` renders with and without `Provider` and checks
  the rendered HTML in both directions — a declared-but-unused param
  would otherwise pass a YAML-only check while changing nothing.

## HowMaHiCo 0.16.1

- **Fixed: the pkgdown site had not deployed since v0.8.0.** pkgdown
  aborts the whole build when an exported function is missing from the
  `_pkgdown.yml` reference index, and three release cycles
  (v0.9.0-v0.13.0) added exports without indexing them: the
  dictionary-driven parser family
  ([`parse_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_unified.md),
  [`read_dictionary()`](https://davidgz1.github.io/HowMaHiCo/reference/read_dictionary.md),
  [`read_custom_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_custom_batch.md),
  [`annotate_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_unified.md),
  [`get_dictionary_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dictionary_template.md)),
  the quality-score engine
  ([`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md)
  and friends, plus
  [`plot_quality_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_quality_heatmap.md),
  [`plot_quality_composite()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_quality_composite.md),
  [`plot_cross_class_length()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_cross_class_length.md))
  and
  [`plot_pseudomobilogram()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pseudomobilogram.md).
  All 15 are now indexed, in two new reference sections plus one
  insertion.
- **New guard `tests/testthat/test-pkgdown-index.R`.**
  `devtools::check()` never reads `_pkgdown.yml`, and the pkgdown
  workflow only runs on `master`, so the failure could only be
  discovered *after* a merge. The suite now checks that every
  [`getNamespaceExports()`](https://rdrr.io/r/base/ns-reflect.html)
  entry appears in the index, that no index entry names a function that
  is not exported (a rename or removal breaks the build the same way),
  and that nothing is listed twice. `_pkgdown.yml` is `.Rbuildignore`d,
  so the test locates it by walking up from the test directory and skips
  when no source tree is reachable.

## HowMaHiCo 0.16.0

- **New report `07_pepchem` + engine `R/pepchem.R`: peptide
  physicochemical properties compared between Conditions.** Where the
  other reports describe *which* peptides were found, this one describes
  what they are made of: amino-acid composition (overall, per sample,
  and as log2 enrichment against the pooled composition of the subset),
  per-position residue frequency at the dominant peptide length plus an
  N-/C-terminal profile resolved across all lengths, and per-peptide
  descriptors — `GRAVY`, `pI`, net `Charge`, `MW`, `Boman`,
  `HydrophobicMoment`, `InstabilityIndex`, `AliphaticIndex` and the
  amino-acid class fractions.
- **The unit of analysis is the sample, not the peptide.** Descriptors
  are computed once over the unique sequences and attached to each
  sample that identified them; each sample is summarised first
  ([`pepchem_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/pepchem_by_sample.md)
  -\>
  [`summarise_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_pepchem.md)
  -\>
  [`aggregate_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/aggregate_pepchem.md))
  and Conditions are then compared across samples. Peptides within a
  Condition are not independent replicates, so pooling them would return
  enormous nominal significance for effects carried by one sample.
- **Two comparison tracks, both labelled.**
  `compare_pepchem(level = "sample")` is the primary,
  replicate-respecting test (Kruskal-Wallis + pairwise Wilcoxon,
  BH-corrected within each contrast, with `MedianDiff` and the new
  scale-free
  [`cliffs_delta()`](https://davidgz1.github.io/HowMaHiCo/reference/cliffs_delta.md)
  as effect sizes) — and is deliberately low-powered: on 3 vs 3 samples
  a two-sided Wilcoxon cannot reach p \< 0.1, the same structural limit
  `06_quant_stats` documents for its Fisher track. `level = "peptide"`
  pools the repertoire and is reported alongside as explicitly
  descriptive.
  [`compare_aa_frequency()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_aa_frequency.md)
  applies the same machinery per residue to per-sample frequencies
  rather than a chi-square on pooled residue counts.
- New exports:
  [`peptide_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/peptide_properties.md),
  [`pepchem_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/pepchem_properties.md),
  [`aa_composition()`](https://davidgz1.github.io/HowMaHiCo/reference/aa_composition.md),
  [`aa_position_frequency()`](https://davidgz1.github.io/HowMaHiCo/reference/aa_position_frequency.md),
  [`pepchem_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/pepchem_by_sample.md),
  [`summarise_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_pepchem.md),
  [`aggregate_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/aggregate_pepchem.md),
  [`cliffs_delta()`](https://davidgz1.github.io/HowMaHiCo/reference/cliffs_delta.md),
  [`compare_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_pepchem.md),
  [`compare_aa_frequency()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_aa_frequency.md),
  plus
  [`plot_aa_composition()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_aa_composition.md),
  [`plot_aa_position_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_aa_position_heatmap.md),
  [`plot_property_distribution()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_property_distribution.md),
  [`plot_property_sample_summary()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_property_sample_summary.md)
  and
  [`plot_property_effectsize()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_property_effectsize.md)
  in `R/plots.R`.
- [`aa_position_frequency()`](https://davidgz1.github.io/HowMaHiCo/reference/aa_position_frequency.md)
  generalises the per-position frequency table that
  [`anchor_information_content()`](https://davidgz1.github.io/HowMaHiCo/reference/anchor_information_content.md)
  collapses to Shannon bits, and the two now share the alphabet and the
  negative-position helper (`-1` = C-terminus) instead of keeping
  duplicate copies.
- **New dependency: `Peptides`** (CRAN, GPL-2, Rcpp only) in `Imports` —
  it is vectorised and is the canonical implementation of GRAVY (mean
  Kyte-Doolittle), so the scales are not re-derived.
  [`Peptides::aaComp()`](https://rdrr.io/pkg/Peptides/man/aaComp.html)
  is not used (it returns a per-sequence list); the class fractions are
  derived from the composition matrix. Its per-descriptor “unrecognized
  amino acid types” warnings are consolidated into one
  [`peptide_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/peptide_properties.md)
  warning naming the count.
- Peptide **position within the parent protein** — the third part of the
  original request — is deferred; no loader carries a position column,
  so it needs a user-supplied search FASTA. The design is recorded under
  *Deferred designs* in `CLAUDE.md`.

### Fixes found while verifying the new report

- **Fixed: `PlotsSave = TRUE` never saved anything, and
  [`ggprint_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/ggprint_rawr.md)
  silently dropped plots.** Both helpers resolved the plot name with a
  bare `exists(deparse(substitute(input)))`, which searches from the
  *helper’s own* frame outwards through its lexical parents — the
  HowMaHiCo namespace, then
  [`globalenv()`](https://rdrr.io/r/base/environment.html) — and so
  never reaches a report’s knit environment
  ([`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html)
  knits in `new.env(parent = globalenv())`). Every lookup from a report
  therefore failed:
  [`ggsave_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/ggsave_rawr.md)
  warned and wrote no png, and
  [`ggprint_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/ggprint_rawr.md)
  returned the warning string instead of the plot, which
  `warning = FALSE` chunks then swallowed. The name is now resolved in
  the **calling** frame via the shared internal `.plot_was_built()`, and
  a non-symbol argument (`plots[[nm]]`, the export-loop idiom used by
  `06` and `07`) is evaluated and judged by value, so a `NULL` plot is
  skipped rather than saved. On the simulated dataset `07_pepchem` goes
  from 8 to 14 figures and from 0 to 14 saved pngs; `04_quant`,
  `05_quality_score` and `06_quant_stats` recover their `PlotsSave`
  output too.
- **Fixed: `05_quality_score` could not render at all.** An inline
  `` `r ...` `` expression ended in a bare comma-separated string list
  (`else "a ", "<code>", params$QCColumn, "</code> b"`) instead of a
  [`paste0()`](https://rdrr.io/r/base/paste.html) call — a syntax error,
  so the template aborted at the inline-parse stage. The report had
  never rendered and nothing caught it, because the suite only rendered
  `01` and `06`; `test-sim-fragpipe.R` now carries a render guard for
  `05` (which also asserts that `PlotsSave` writes files and that
  figures reach the HTML).

## HowMaHiCo 0.15.0

- **Mouse MHC-I support.** `MHCclass` accepts a new value
  **`"MHC1_mouse"`** (7-11 AAs, the murine H-2 ligand window) alongside
  `"MHC1"` (8-13) and `"MHC2"` (12-25). The windows and their palettes
  now come from two exported helpers,
  [`mhc_length_window()`](https://davidgz1.github.io/HowMaHiCo/reference/mhc_length_window.md)
  and
  [`mhc_class_palette()`](https://davidgz1.github.io/HowMaHiCo/reference/mhc_class_palette.md)
  (`R/report-helpers.R`), instead of three copy-pasted lists in the
  skeletons and a fourth inside the quality-score engine.
- **Quality score is mouse-aware**: for `"MHC1_mouse"` the
  canonical-length metric counts **8- and 9-mers** (H-2Kb favours
  8-mers, H-2Db 9-mers) with the label “8/9-mer fraction” and raised
  green/amber cut-offs
  ([`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md)
  gained an `mhcclass` argument); the anchor motif is scored on
  whichever of the two lengths the sample has more of; the cross-class
  window follows the 7-11 window. The metric *keys* are unchanged.
- **Fixed: a single-Condition subset aborted every report.**
  `combn(conditions, 2)` errors with `n < m`; the new exported
  [`condition_pairs()`](https://davidgz1.github.io/HowMaHiCo/reference/condition_pairs.md)
  returns an empty list instead (and `self = TRUE` gives the overlap
  matrix its diagonal), and the skeletons use it. Guarded by an
  end-to-end single-Condition render test.
- **Fixed: an all-zero `Area` dataset aborted the render.**
  [`get_mat_log2area()`](https://davidgz1.github.io/HowMaHiCo/reference/get_mat_log2area.md)
  now returns a well-formed `0 x n` matrix with a warning when every ID
  is a phantom, and the correlation chunks of `04_quant` /
  `00_mhc_report` test for that *before* calling
  [`cor()`](https://rdrr.io/r/stats/cor.html) (which errors with
  `'x' is empty`) and before computing the colour limits.
- **`TestMode` now builds a representative minimal dataset.** It used to
  read only the first ~100 lines of each file, which for a combined
  FragPipe `psm.tsv` (one file holding every run) kept just the first
  run and broke the annotation join. Files are now read in full and
  reduced to ~100 rows **per run**, so every run, Condition and
  replicate survives. The misleading “only the first 50 lines were
  loaded” warning is gone.
- **One annotation format for every search engine.**
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md)
  accepts a canonical **`Sample_folder`** column and derives the
  loader-facing aliases from it (`Sample_fp` verbatim, `Sample_peaks`
  with PEAKS’ hyphen/space normalization). Legacy tables providing
  `Sample_fp` or `Sample_peaks` load unchanged, and a user-supplied
  alias is never overwritten.
  [`get_annot_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_fragpipe.md)/[`get_annot_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_diann.md)
  now emit `Sample_folder` instead of `Sample_fp` (**user-visible change
  to the generated skeleton**), and PEAKS finally has a generator of its
  own:
  **[`get_annot_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_peaks.md)**.
- **[`get_annot_sampleid()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_sampleid.md)
  no longer fails silently**: it warns when nothing matched the sample
  list (showing example `Source_file` values from both sides) and when
  only some rows matched (naming the dropped ones), and gained
  `keep_all = TRUE` to left-join so no annotation row is lost.
- New tests: `test-report-helpers.R`; all-zero-`Area` coverage in
  `test-counting.R`;
  `Sample_folder`/[`get_annot_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_peaks.md)/[`get_annot_sampleid()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_sampleid.md)
  coverage in `test-annotation.R`; mouse metrics in
  `test-quality-score.R`; per-run test-mode subsampling in
  `test-loaders-fragpipe.R`; single-Condition and mouse-window
  end-to-end renders in `test-sim-fragpipe.R`.

## HowMaHiCo 0.14.0

- **New advanced-quantification report `06_quant_stats`** and its engine
  `R/quant-stats.R`: multivariate and differential statistical
  comparison of peptide `Area` between Conditions, rendered against the
  cached `pep_all` like the other focused reports. Sections:
  quantitative matrix and filtering summary, data completeness (per unit
  / per feature / presence-absence map), normalization diagnostics,
  dynamic range, optional imputation diagnostics, unsupervised overview
  (PCA scores/scree/loadings, clustered **and** unclustered heatmaps,
  PERMANOVA-style permutation test), per-contrast differential abundance
  (volcano, MA, p-value histogram, top-feature table), a
  presence/absence section for condition-exclusive ligands, a
  significance summary, and a “Methods & justification” section
  documenting every choice.
- **New exported engine functions**:
  [`build_quant_matrix()`](https://davidgz1.github.io/HowMaHiCo/reference/build_quant_matrix.md)
  (long `pep_all` -\> feature x unit log2 matrix; `Area` summed over
  precursors on the linear scale, technical replicates averaged),
  [`filter_quant()`](https://davidgz1.github.io/HowMaHiCo/reference/filter_quant.md),
  [`normalize_quant()`](https://davidgz1.github.io/HowMaHiCo/reference/normalize_quant.md),
  [`impute_quant()`](https://davidgz1.github.io/HowMaHiCo/reference/impute_quant.md),
  [`test_differential()`](https://davidgz1.github.io/HowMaHiCo/reference/test_differential.md),
  [`test_detection()`](https://davidgz1.github.io/HowMaHiCo/reference/test_detection.md),
  [`combine_quant_results()`](https://davidgz1.github.io/HowMaHiCo/reference/combine_quant_results.md),
  [`summarise_significant()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_significant.md),
  [`permanova_condition()`](https://davidgz1.github.io/HowMaHiCo/reference/permanova_condition.md).
- **New plots**:
  [`plot_completeness()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_completeness.md),
  [`plot_missing_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_missing_heatmap.md),
  [`plot_intensity_dist()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_intensity_dist.md),
  [`plot_dynamic_range()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_dynamic_range.md),
  [`plot_pca()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pca.md),
  [`plot_quant_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_quant_heatmap.md)
  (clustered/unclustered, ggplot2 — printable inside a tabset, unlike
  the png-writing
  [`plot_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_heatmap.md)),
  [`plot_volcano()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_volcano.md),
  [`plot_ma()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_ma.md),
  [`plot_pvalue_hist()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pvalue_hist.md),
  [`plot_sig_summary()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_sig_summary.md).
- **Two complementary missing-value tracks.** limma moderated
  t-statistics (`eBayes(trend = TRUE, robust = TRUE)`) on the observed
  values, optionally after left-censored imputation (`minprob` /
  `mindet`), *plus* a Fisher exact test on detection counts for
  condition-exclusive features, whose fold change is undefined.
  Exclusivity is flagged by a detection-count rule rather than an FDR
  cut-off, because a 3-vs-3 Fisher test cannot go below p = 0.1.
- **`limma` is a `Suggests` dependency**, not an `Imports`: it is
  guarded at runtime (with a `BiocManager::install("limma")` message)
  and `StatMethod = "ttest"` / `NormMethod = "median"` give a fully
  Bioconductor-free path, which the report falls back to automatically.
- **Fixed: `run_howmahico_report("05_quality_score")` was unreachable**
  — the template was documented but missing from the function’s
  `template` choices, so
  [`match.arg()`](https://rdrr.io/r/base/match.arg.html) rejected it.
  Both `05_quality_score` and `06_quant_stats` are now registered, and
  `tests/testthat/test-report-templates.R` guards that every shipped
  template directory appears in the choices.
- `tests/testthat/test-quant-stats.R` covers the engine (aggregation,
  filtering, normalization, imputation, limma/t-test agreement,
  detection test, PERMANOVA, the limma guard); `test-sim-fragpipe.R`
  renders `06_quant_stats` end-to-end against the simulated FragPipe
  dataset.

## HowMaHiCo 0.13.0

- **Pseudochromatogram coloured by density.**
  [`plot_pseudochromatogram()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pseudochromatogram.md)
  now fills the RT bars by their own peptide count (continuous viridis
  gradient) instead of a flat per-Condition colour, so dense RT regions
  stand out within each facet.
- **New
  [`plot_pseudomobilogram()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pseudomobilogram.md)**
  — ion-mobility analogue of the pseudochromatogram: per-Condition
  peptide count vs `invk0` (1/k0), binned by a configurable `binwidth`
  (default `0.2`), bars coloured by count. Wired into the `03_lcms_qc`
  RT/1k0/mz view config (new “Pseudomobilograms” tab) and the
  `00_mhc_report` distribution section (all / selected peptides).
- **Charge-proportion bars** now carry a black outline
  ([`plot_charge_proportions()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_charge_proportions.md)),
  matching the other stacked bar charts.
- **Peptide motifs** extended to the **7–25 AA** window (was capped at
  24); section retitled “Peptide motifs (7 to 25 AAs)” in `01_id_counts`
  and `00_mhc_report`.
- **Subset prefix on all result files.** The focused reports’ shared
  `setup.Rmd` (and the two `00_*` reports) now derive a `result_prefix`
  (`= Subset`, or `NULL` when unset) and pass it to every
  [`write.csv_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/write.csv_rawr.md)
  /
  [`write_input_params()`](https://davidgz1.github.io/HowMaHiCo/reference/write_input_params.md)
  call and the `seq_by_condition.xlsx` write, so result filenames carry
  the subset (e.g. `dda_all_pep_all.csv`). `input_params` combines the
  subset with the report name to stay collision-free within a shared
  subset subfolder.
- `tests/testthat/test-plots.R`: smoke coverage for
  [`plot_pseudochromatogram()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pseudochromatogram.md)
  and
  [`plot_pseudomobilogram()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pseudomobilogram.md)
  (incl. a custom `binwidth`).

## HowMaHiCo 0.12.0

- `01_id_counts`: new **Average +/- sd per BioReplicate** section
  mirroring the per-Condition one (mean ± SD across the TechReplicate
  samples within each BioReplicate).
  [`plot_count_mean_sd()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_count_mean_sd.md)
  gains a `group_var` argument (default `"Condition"`; pass
  `"BioReplicate"`) controlling the x-axis/fill.
- `01_id_counts`: **Proportion by length** is now its own top-level
  section with Condition / BioReplicate / Sample tabs (was two nested
  subsections under the Total-by-Condition / Total-by-Sample sections).
- `02_overlaps`: new **Overlap intra-Condition (%)** section showing the
  replicate-overlap bars as a per-Condition percentage (stacked to
  100%).
  [`plot_overlap_intra_condition()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_overlap_intra_condition.md)
  gains a `value` argument (`"count"` default, or `"percent"`).
- Report headers reading “Selected peptides” now show the active length
  window (e.g. “Selected peptides (8 to 13 AAs)”), derived from
  `shortpep_range`, across the focused templates.
- Renamed the “Proteins” ID-level **headers/labels** to “Parent
  proteins” in the focused `01_id_counts` / `02_overlaps` reports
  (display only; the data keys and plot axis labels are unchanged).
- `tests/testthat/test-plots.R`: smoke coverage for
  [`plot_count_mean_sd()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_count_mean_sd.md)
  (both `group_var` modes) and
  `plot_overlap_intra_condition(value = "percent")`.

## HowMaHiCo 0.11.0

- Added a **cross-class (MHC1↔︎MHC2) contamination** dimension to the
  quality score: `frac_cross_class` flags MHC-II ligands co-enriched in
  an MHC-I pulldown (and vice versa) via their length signature — the
  fraction of peptides in the *other* class’s canonical window (MHC1
  8-13, MHC2 12-25) that falls outside the current window (so the 12-13
  AA overlap is handled cleanly). Scored `lower_better` at low weight (a
  small tail is biologically normal) and `NA` (dropped) for custom
  length windows. New internal helper `.cross_class_range()` is the
  single source of truth for the windows.
- New plot
  [`plot_cross_class_length()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_cross_class_length.md):
  per-sample faceted length histogram with the cross-class region
  highlighted, and a matching “Cross-class contamination” section +
  Methods bullet in the `05_quality_score` report.
- `tests/testthat/test-quality-score.R`: covers `.cross_class_range()`,
  the new
  [`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md)
  row, and `frac_cross_class` on an inline fixture.

## HowMaHiCo 0.10.0

- Added a per-sample **immunopeptidomics quality score** (inspired by
  the author’s HowDirty contamination score, but inverted: it scores how
  strongly a sample resembles a real HLA immunopeptidome rather than its
  contaminant load). New scoring engine in `R/quality-score.R`, all from
  the `pep_all` schema with no external data and no new dependency.
- New exports:
  [`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md)
  (per-sample composite + traffic-light category),
  [`qc_metrics_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/qc_metrics_by_sample.md)
  (raw signals: length-window fidelity, 9-mer dominance, anchor-motif
  clarity, non-tryptic specificity, charge plausibility, depth, mass
  accuracy),
  [`anchor_information_content()`](https://davidgz1.github.io/HowMaHiCo/reference/anchor_information_content.md),
  [`score_curve()`](https://davidgz1.github.io/HowMaHiCo/reference/score_curve.md),
  [`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md),
  [`calibrate_thresholds_from_qc()`](https://davidgz1.github.io/HowMaHiCo/reference/calibrate_thresholds_from_qc.md),
  plus plots
  [`plot_quality_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_quality_heatmap.md)
  and
  [`plot_quality_composite()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_quality_composite.md).
- The non-tryptic signal is deliberately low-weight and split: because
  some HLA-I alleles legitimately use K/R as a C-terminal anchor, the
  overall C-terminal K/R fraction is a low-weight diagnostic, while the
  scored metric isolates tryptic background in the out-of-window
  (long-peptide) tail.
- Thresholds use built-in literature defaults **or** are calibrated from
  samples tagged as experiment QC controls via an optional annotation
  `QC` column (`ThresholdMode = "qc_relative"`) — no external benchmark
  dataset needed. Undefined dimensions (e.g. MHC-II anchors, DIA-NN
  dummy `ppm`) drop out of the weighted composite rather than penalising
  the sample.
- New focused report template `05_quality_score`
  (`inst/rmarkdown/templates/05_quality_score/`): traffic-light
  overview, composite bar chart, per-metric breakdown and a
  self-documenting Methods section, rendered against the cached
  `pep_all` like the other focused reports.
- `tests/testthat/test-quality-score.R`: pure-math boundary checks of
  [`score_curve()`](https://davidgz1.github.io/HowMaHiCo/reference/score_curve.md)
  (no synthetic peptide data required).

## HowMaHiCo 0.9.0

- Added a dictionary-driven **unified parser** so a tabular
  search-engine export from a tool HowMaHiCo has no built-in loader for
  can be ingested by editing a YAML dictionary — no R coding, no new
  loader. New
  [`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
  branch `software = "custom"` (with a `dictionary` argument) routes
  through
  [`read_custom_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_custom_batch.md)
  →
  [`parse_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_unified.md)
  →
  [`annotate_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_unified.md).
  The dictionary maps raw → `pep_all` columns, sets the `Found_By`
  constant, and derives the shared recipe (`Log2Area`, `Length_range`,
  `Nter`/`Cter`, `PeptideID`, `Charge` formatting); per-tool transforms
  (unit conversions, regex extraction, accession splitting) are
  pre-clean responsibilities, not expressed in the dictionary.
- New exports:
  [`read_dictionary()`](https://davidgz1.github.io/HowMaHiCo/reference/read_dictionary.md),
  [`parse_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_unified.md),
  [`read_custom_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_custom_batch.md),
  [`annotate_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_unified.md),
  and
  [`get_dictionary_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dictionary_template.md)
  (copies a fill-in template to the working dir, sibling of
  [`get_report_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_report_template.md)).
- Shipped reference dictionaries in `inst/extdata/dictionaries/`
  (`custom_template.yaml` + `fragpipe.yaml` / `diann.yaml` /
  `peaks.yaml` documenting the directly-mappable subset of each built-in
  loader). The three built-in loaders are unchanged.
- `tests/testthat/test-parse-unified.R`: asserts
  [`parse_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_unified.md)
  reproduces the built-in FragPipe loader on the directly-mappable
  columns of the simulated dataset, plus dictionary validation and the
  custom
  [`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
  path.
- New dependency: `yaml` (already transitive via `rmarkdown`).

## HowMaHiCo 0.8.0

- The four focused reports (`01_id_counts`, `02_overlaps`, `03_lcms_qc`,
  `04_quant`) gained a `PepAllSource` param (with `PepAllFile`)
  selecting how to obtain `pep_all`: `"cached"` (default — load the
  `<Subset>_pep_all.rda` cache, the prior behavior), `"rda"` (load an
  explicit `.rda`), or `"build"` (parse the raw search output via
  [`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
  and write the cache). A focused report can now be rendered straight
  from results without a separate
  [`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
  call. Backward compatible — the default reproduces the old behavior.
- Added a simulated FragPipe dataset (`inst/extdata/sim_fragpipe_dda/`,
  2 Conditions x 3 BioReplicates, generated with MaHiCoInSilico) and
  `tests/testthat/test-sim-fragpipe.R`: a
  [`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
  loader assertion plus the first end-to-end render test of a focused
  report (gated on `skip_on_cran()` / pandoc). Moving the data out of
  `data/` into `inst/extdata/` also clears the R CMD check warnings
  about non-R files in `data/`.

## HowMaHiCo 0.7.1

- Fixed a “Duplicate chunk label ‘setup’” parse error that aborted every
  focused report (`01_id_counts`, `02_overlaps`, `03_lcms_qc`,
  `04_quant`). The shared `inst/rmarkdown/shared/setup.Rmd` had a fenced
  r-chunk example inside its leading HTML comment; knitr parses chunk
  headers even inside comments, so that example re-included the file and
  duplicated the `setup` chunk. The comment now describes the include in
  prose, and a regression test guards against reintroducing a chunk
  fence there. (The two all-in-one reports were unaffected.)

## HowMaHiCo 0.7.0

- **Breaking: renumbered all report templates.** The `template=` value
  passed to
  [`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md)
  /
  [`get_report_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_report_template.md)
  changes: `01_mhc_report` → `00_mhc_report`, `02_mhc_upsets` →
  `00_mhc_upsets`, `03_id_counts` → `01_id_counts`, `04_overlaps` →
  `02_overlaps`, `05_lcms_qc` → `03_lcms_qc`, `06_quant` → `04_quant`.
  The two all-in-one reports take the `00_` prefix; the focused reports
  fill `01–04`.
- The LC-MS report’s “Peptide ID distribution across RT, 1/k0 and m/z”
  section is now generated by a single looped `results='asis'` chunk (a
  config list of the four views × the all/selected peptide sets) instead
  of eight hand-written chunks, matching the looped style of the motif /
  overlap sections.

## HowMaHiCo 0.6.1

- Moved the PTM profile from `05_lcms_qc` to `03_id_counts` (it is a
  general identification property, alongside peptide motifs), and
  extended it to show **all peptides** (`pep_all`) in addition to the
  selected-length peptides (`pep_short`), in an All / Selected tabset —
  matching the other dual sections. `05_lcms_qc` now covers only the
  RT/1k0/mz distributions and Score/ppm QC.

## HowMaHiCo 0.6.0

### Multi-report framework

- New exported
  [`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
  extracts the raw-file parsing step (the FragPipe / DIA-NN / PEAKS read
  → parse → annotate dispatch) into a standalone, unit-tested function
  that writes the `<Subset>_pep_all.rda` cache. Run it once, then render
  any of the focused reports against that cache instead of re-parsing
  the raw search files per report.
- Four new focused report templates, each a slice of the all-in-one
  `01_mhc_report`, rendered the same way via
  [`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md):
  - `03_id_counts` — total IDs, identification counts (mean±sd, by
    length, by charge, by sample), peptide size distributions, peptide
    motifs.
  - `04_overlaps` — intra-Condition replicate overlap, UpSet across
    Conditions, and Condition pairwise overlap.
  - `05_lcms_qc` — RT / 1k0 / m/z distributions, Score and mass-error
    identification QC, and the PTM profile (advanced LC-MS QC).
  - `06_quant` — log2(Area) correlation and Area %CV violins.
- The focused reports share one setup fragment
  (`inst/rmarkdown/shared/setup.Rmd`, pulled in via a knitr `child`)
  that loads the cache and derives the common objects, instead of
  duplicating the boilerplate in every skeleton.
- `01_mhc_report` and `02_mhc_upsets` are unchanged — full
  retrocompatibility.

## HowMaHiCo 0.5.0

### Report: per-length splits for the overlap and charge sections

- [`plot_overlap_intra_condition()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_overlap_intra_condition.md)
  now returns a single replicate-overlap bar chart for one data frame
  and one ID level, instead of stacking all-vs-selected peptides into a
  two-row
  [`ggpubr::ggarrange()`](https://rpkgs.datanovia.com/ggpubr/reference/ggarrange.html).
  **Breaking signature change**: the arguments are now
  `(df, id_col, title = NULL, shortpep_range)` (previously
  `(pep_all, pep_short, id_col, shortpep_range)`). The main report’s
  “Overlap intra-Condition” section now presents All peptides and
  Selected peptides as separate nested tabsets (Peptides / Sequences /
  Proteins), matching the “Average +/- sd” section.
- The “Peptides identified per charge +1 to +4” section now renders a
  plot for the selected-length peptides (`pep_short`) alongside the
  all-peptides plot, in an All peptides / Selected peptides tabset. The
  selected-length plot is also written out when `PlotsSave = TRUE`.

## HowMaHiCo 0.4.0

### Loader consistency & portability

- Unified `Log2Area` zero-handling across all three loaders: a zero
  `Area`/`Intensity` now maps to `NA` everywhere. Previously FragPipe
  and DIA-NN mapped it to `1` while PEAKS mapped it to `NA`, so the same
  zero-area row behaved differently depending on the search engine.
  **This changes FragPipe/DIA-NN output for zero-area rows** — they no
  longer carry a fabricated `Log2Area = 1`. The shared logic now lives
  in an internal `compute_log2area()` helper.
- Run-name extraction (DIA-NN `File.Name`, Bruker HyStar `Result.Path`)
  is now separator-agnostic via an internal `extract_run_name()` helper,
  replacing a backslash-anchored regex that only worked on Windows-style
  paths. The loaders are now portable to Linux/macOS (and Docker).
- Each `parse_*()` validates its output against the core `pep_all`
  schema (`validate_pep_all()`), so a loader that drops/renames a core
  column or returns an empty table fails loudly at the source instead of
  producing a half-broken report several sections later.

### Report robustness & provenance

- The main report (`01_mhc_report`) no longer aborts on partial subsets:
  the UpSet sections skip gracefully when fewer than two Conditions are
  present, and the Area %CV sections render an explanatory note instead
  of erroring when no replicates exist.
- Both report templates gained a “Session & provenance” footer: the run
  parameters as a table, the package version, and a collapsible
  [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html), so a
  saved HTML is self-documenting.
- Declared the previously-undeclared `DataAcquisitionNames` parameter in
  the `02_mhc_upsets` template (it was referenced in the header but
  never defined in the YAML, so it rendered blank).

## HowMaHiCo 0.3.0

### Packaging & best-practices cleanup

- Declared the previously-undeclared base-package dependencies
  (`grDevices`, `graphics`, `stats`, `utils`) in `DESCRIPTION`
  `Imports`.
- The full exported function set is now part of the public reference:
  removed `@keywords internal` from every exported function (the
  package-overview page and the non-exported helpers stay internal), and
  listed every export in `_pkgdown.yml`.
- All package R code — both the `R/` source and the two report templates
  (`inst/rmarkdown/templates/*/skeleton/skeleton.Rmd`) — now uses the
  native R pipe (`|>`) throughout instead of magrittr `%>%`. **This
  raises the minimum R version to 4.1.0** (`Depends: R (>= 4.1.0)`).
- De-vendored
  [`get_dirs_index_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dirs_index_peaks.md):
  the helper (originally adapted from `deltaProtR`) is now native
  HowMaHiCo code in `R/loaders-peaks-dirs.R` (was
  `R/vendored-deltaprotr.R`).
- Added this `NEWS.md` changelog.

### Bug fixes

- [`check_file_exists()`](https://davidgz1.github.io/HowMaHiCo/reference/check_file_exists.md)
  now names the conflicting file in its error/warning message (the
  filename was previously printed after
  [`stop()`](https://rdrr.io/r/base/stop.html), so it never appeared).
- [`check_output_exists()`](https://davidgz1.github.io/HowMaHiCo/reference/check_output_exists.md)
  no longer lists `upset_table_prot.csv` twice.
- The log2(Area) heatmap “saved in” message now reports the actual
  output path instead of a hardcoded `4_figures/...` string.

## HowMaHiCo 0.2.1

- Peptide motifs (seqlogo) now shown up to length 24 (was 22).
- Identification counts “Average ± sd” split into per-length individual
  plots and nested tabsets, with all-peptides vs selected-peptides shown
  separately.
- “Peptide ID distribution across RT, 1/k0 and m/z” refactored out of
  the template into
  [`plot_pseudochromatogram()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pseudochromatogram.md)
  and
  [`plot_2d_distribution()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_2d_distribution.md).
- Replaced hardcoded `scale_y_continuous()` breaks/labels with
  `n.breaks = 5` in
  [`plot_bp_count_length()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_bp_count_length.md),
  [`plot_count_mean_sd()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_count_mean_sd.md),
  and
  [`plot_overlap_intra_condition()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_overlap_intra_condition.md).
- Homogenized bar `alpha = 0.7` and added black outlines across plot
  functions.
- Fixed
  [`count_ids_condition_bylengthrange()`](https://davidgz1.github.io/HowMaHiCo/reference/count_ids_condition_bylengthrange.md)
  dropping an existing `Condition` column before renaming.

## HowMaHiCo 0.2.0

- Completed Phases 1–6 of the conversion into a proper R package:
  functions moved into `R/`, report templates shipped under
  `inst/rmarkdown/templates/{01_mhc_report,02_mhc_upsets}/`, a testthat
  (edition 3) suite, roxygen `man/` pages, `_pkgdown.yml`, and CI
  (R-CMD-check + pkgdown).
- Added a proportion-by-length plot at the sample level to the “Total by
  Sample” section.
- [`plot_peplength_hist()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_peplength_hist.md)
  density normalized by condition total rather than per-group.

## HowMaHiCo 0.1.4

- Fixed rendered `output_file` landing in the installed package library
  instead of the working directory.

## HowMaHiCo 0.1.3

- Named all report chunks and unified `fig.width = 8` across chunks.
- Added
  [`plot_peplength_hist()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_peplength_hist.md)
  (a simpler length-distribution histogram without the boxplot overlay,
  facetable, two-color by `MHCclass`, density or absolute).

## HowMaHiCo 0.1.2

- Introduced
  [`theme_howmahico()`](https://davidgz1.github.io/HowMaHiCo/reference/theme_howmahico.md)
  and applied it across plot functions and report skeletons.
- `MHCclass` parameter with default length windows (MHC1: 8–13 AA, MHC2:
  12–25 AA) and a manual color/fill palette per class.
- Added a pre-flight check that every file named in the annotation table
  exists, a per-sample “Total by Sample” section, and a programmatically
  generated report title.

## HowMaHiCo 0.1.1

- Suppressed the progress bar in
  [`get_annot_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_diann.md).

## HowMaHiCo 0.1.0

- First package-shaped release. Renamed the report templates to
  `01_mhc_report` and `02_mhc_upsets`; split
  [`read_peaks_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks_batch.md)
  into read/parse/annotate matching the FragPipe/DIA-NN loader families;
  batch readers now read only the files referenced in the annotation
  table.
