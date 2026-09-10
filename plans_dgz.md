# plans_dgz.md - HowMaHiCo

## What this is

Plans by DGZ to improve HowMaHiCo.

Instructions: when prompted, you can read this file and provide a plan
to do the pending tasks in “to do”. When something is done, move it to
the end of “Done”. Do not consider the points in “In standby”, until
they are moved to “to do”

## To do

## In standby

- peptide position within the parent protein (the third part of the
  physicochemical-properties item) — deferred; it is the only part that
  needs a user-supplied search FASTA, since no loader carries a position
  column (FragPipe psm.tsv, DIA-NN report.tsv and PEAKS peptide.csv all
  lack one). Full design recorded in CLAUDE.md under “Deferred designs”.

- implement safeguard when some conditions or replicates give 0 areas,
  currently throwing error — moved to standby (no repro available;
  e.g. CHEB_001 all dda dataset not in repo). The all-NA Area/CV and
  all-NA correlation cases are already guarded in the report chunks; the
  partial (some groups 0/NA) failure needs a repro to target.

- For PTM plots, translate unimod code into modification name — deferred
  (full implementation design saved in
  memory/project_ptm_translation_plan.md). Scope chosen: translate BOTH
  UniMod accessions AND delta masses to names. Key gotcha: only DIA-NN
  stores UniMod codes (UniMod:NN); FragPipe (default/sim) and PEAKS
  store delta masses. Plan: new R/ptm.R with ptm_reference() +
  translate_ptm(), wired into plot_ptm_heatmap() as a display-time
  translate=TRUE arg; correct the wrong PTM note in 01_id_counts
  skeleton.

- InteractivePlots (TRUE/FALSE) toggle to render compatible plots via
  ggplotly — deferred: most compatible plots print inside results=‘asis’
  tabset loops where embedding plotly htmlwidgets (vs static ggplots) is
  finicky and only render-verifiable, which we don’t do in-session.
  Groundwork ready: plotly already in Imports + loaded in shared
  setup.Rmd; ggplotly already used for the correlation plots (04_quant
  L110/L143). Skip ggseqlogo / ggupset / ggvenn / ggarrange composites /
  base plot_heatmap.

- Calculate an fdr for length distribution. What’s the probability of
  detecting the length distribution vs. the background proteome?

- Total by Condition /BioReplicate / Sample in tabs

- more explicit errors, e.g., when files are not found

- autogenerate Sample by concatenating the others

- bioreplicate as numbers or text, without condition, gets merged
  afterwards

- maybe generate a report in long format

- include whole folder with dia-quant-output when diann

- check and deal with license discrepancies between howmahico, peptides,
  limma

- 

### to be done by DGZ

- Check and complete glosary
- check/add functionality for peaks Xpro
- 2do by me, check Overlap intra-Condition seems to be showing peptides
  in sequences, and sequences+proteins in proteins - corrected in the
  individual reports, but not in the legacy main report
- reorder plots in a way that makes more sense
- manual checking and re-writing text by me
- add more detailed instructions to the readme
- make a runnable R code with instructions based on the readme, use
  render instead of opening the report
- check way sample_annotation is named in the reports, should be the
  same as in the example
- check which column is used as quant for each software
- get_report_template change param order, start with template then file

## advanced plans

- include MaHiCoBench dataset for LFQbench-style plots
- Dataset: use the JY hla1 and hla2 from Annica and Julian
- Simple summary of HowMaHiCo ala HowDirty
- Push a v1 and publication with this dataset before adding many more
  functionalities
- Maybe switch TechRep to InjRep
- Standardize headers, include a function to convert from old to new
  headers
- Wheremahico = peptide distribution in the protein. Add a widget to
  show location of peptides in specific protein
- Whichmahico = detect which alleles
- Ismahico= binding prediction
- HowConta = summary of common contaminants
- Another idea: hla allotyping from hla peptides in the ip data
- include code for nc.
- add tag for nc. exclusive, shared with up, up exclusive

## Done

- deal with code possibly buried in a folder, e.g. as option in setup:

opts_knit\$set(root.dir = normalizePath(“..”))

- libraries not being loaded: kableExtra, ggpubr, viridis, plotly,
  openxlsx, dplyr

- standardize function names:

  - loaders as read_software for individual files and
    read_software_batch for multiple inputs
  - read_software_batch include the option to provide the annotation and
    only read files referenced in the table, or a simple vector
  - also rename the parse functions

- I ran a test in a parallel session. There is an error on chunk 20,
  rownames_to_column function was not found. library(tibble) is missing.

- convert 00_extract_sample_info_fragpipe to functions in
  loaders-fragpipe

- I moved the original folders and their contents to example. Check that
  it doesn’t break anything, and also add that folder itself to
  .gitignore

- add :

get_report_template \<- function(file = “HowMaHiCoReportTemplate”, edit
= FALSE, create_dir = FALSE) {

rmarkdown::draft(file = file,

template = “howmahico-report”,

edit = edit,

package = “HowMaHiCo”,

create_dir = create_dir)

}

- correct mentions of “suffix” to “subset”

- check if it is possible to simplify the params entered in
  howmahico-report, provide a plan

- the batch readers currently read all the files in the data folder,
  then drop what is not in the annotation table. provide a plan to only
  read what is needed.

- read_peaks_batch has to be split because it currently includes the
  parser inside

- update readme and documentation following the example in
  example/0\\code/00\\pipeline\\example

- rename templates howmahico-report to 01\\mhc\\report, and
  howmahico-upsets to 02\\mhc\\upsets, the required functions and
  documentation

- implement default modes for:

  - MHC1, ShortPeptideLengthMin = 8, ShortPeptideLengthMax = 13
  - MHC2, ShortPeptideLengthMin = 12, ShortPeptideLengthMax = 25

- standardize report title by generating it programmatically. Include:
  template name, SampleSet, subset, MHCclass, date

- Adapt color/fill palette for all the plots where the shortpep_range is
  used as aesthetic. Use manual scale instead of viridis. If MHCclass =
  MHC1, use c(“#fde725”, “#440154”); If MHCclass = MHC2, use
  c(“#21918c”, “#440154”). If custom lengths, use the same palette as
  MHC1

- in the pipeline (in example and also documentation), include a step to
  check if all the files named in the annotation table exist. print the
  list of files missing, and then stop with an error.

- in 01_mhc_report, add a section replicating section “## Total by
  Condition”, but the x axis should be each sample

- homogenize the theme across the plotting functions: created
  theme_howmahico, applied to all plotting functions and report
  skeletons. Also homogenized font sizes for labels, axes, and
  annotations.

- homogenize fig.width across all the chunks to 8.

- add names to chunks

- peptide length distribution, create a simpler function without the
  boxplot on top. This should facilitate using facet instead of
  ggarrange, include the option to color bars using two colors, based on
  the MHCclass. Also include option to show density or absolute numbers.
  In report, include both versions as sub-sections within a .{tabset}

- add Proportion by length at sample level to \## Total by Sample

- some plots use scale_y_continous with fixed breaks and labels. Changed
  to n.breaks = 5 in plot_bp_count_length, plot_count_mean_sd,
  plot_overlap_intra_condition

- Peptide motifs: show up to length = 24 (was 22)

- # Identification counts \## Average +/- sd: all peptides and selected peptides shown separately in nested tabsets

- “# Peptide ID distribution across RT, 1/k0 and m/z”: extracted to
  plot_pseudochromatogram() and plot_2d_distribution(); skeleton
  simplified to 1-2 lines per chunk

- 2do by me,Identification counts, average +/-sd, split into individual
  plots for each length

- add to the readme as optional subpoint in complete the annotation csv:
  complete the annotation table with the Sample_ID from the Hystar
  sample list using get_annot_sampleid

- de-vendor get_dirs_index_peaks: removed the vendored/deltaProtR
  provenance, renamed R/vendored-deltaprotr.R to R/loaders-peaks-dirs.R,
  converted its pipes to \|\> (v0.3.0)

- unify the two report templates (01_mhc_report, 02_mhc_upsets
  skeleton.Rmd) on the native \|\> pipe (181 %\>% converted; verified
  via knitr::purl + parse) (v0.3.0)

- 2do by me change purple color of length plots to a dimmer one

- Overlap intra-Condition (across replicates), split into individual
  plots for each length: plot_overlap_intra_condition() refactored to
  single-plot (df, id_col, title); report section now All peptides /
  Selected peptides nested tabsets (v0.5.0)

- Peptides identified per charge +1 to +4, one plot for all peptides
  (pep_all) and one for selected length (pep_short), shown in an All /
  Selected tabset (v0.5.0)

- multi-report framework instead of one big report: exported
  build_pep_all() (parse+cache step), shared
  inst/rmarkdown/shared/setup.Rmd child, and four focused templates
  03_id_counts / 04_overlaps / 05_lcms_qc / 06_quant rendered against
  the cached pep_all; 01_mhc_report kept unchanged for
  retrocompatibility (v0.6.0)

- PTM profile moved from 05_lcms_qc to 03_id_counts, and extended to
  show all peptides (pep_all) alongside selected (pep_short) in an
  All/Selected tabset (v0.6.1)

- renumbered all report templates: 01_mhc_report-\>00_mhc_report,
  02_mhc_upsets-\>00_mhc_upsets, 03_id_counts-\>01_id_counts,
  04_overlaps-\>02_overlaps, 05_lcms_qc-\>03_lcms_qc,
  06_quant-\>04_quant (v0.7.0)

- lcms_qc RT/1k0/m_z distribution section rewritten to a single looped
  results=‘asis’ chunk (config list of views x peptide sets) instead of
  8 hand-written chunks (v0.7.0)

- fixed “Duplicate chunk label ‘setup’” parse error in the focused
  reports: shared setup.Rmd had a fenced r-chunk example inside its
  leading HTML comment (knitr parses chunks even in comments -\>
  recursive re-include); comment is now prose + regression guard test
  (v0.7.1)

- focused reports gained PepAllSource param (cached / rda / build) so
  each can load the default cache, load an explicit .rda (PepAllFile),
  or self-build from raw results via build_pep_all(); default = cached =
  prior behavior (v0.8.0)

- added simulated FragPipe data (inst/extdata/sim_fragpipe_dda, moved
  out of data/) + test-sim-fragpipe.R: build_pep_all assertion + first
  end-to-end render test of a focused report (v0.8.0)

- unified parser using dictionaries with option to enter a custom entry
  from other software: dictionary-driven parse_unified() +
  read_custom_batch() + annotate_unified() +
  read_dictionary()/get_dictionary_template(), wired into
  build_pep_all(software=“custom”, dictionary=…); YAML dictionaries in
  inst/extdata/dictionaries (custom_template + fragpipe/diann/peaks
  reference); built-in loaders untouched; test-parse-unified.R
  round-trips against the FragPipe loader (v0.9.0)

- immunopeptidomics sample quality score (HowDirty-inspired, inverted):
  R/quality-score.R (score_sample_quality + qc_metrics_by_sample +
  anchor_information_content + score_curve +
  quality_thresholds_default + calibrate_thresholds_from_qc),
  plot_quality_heatmap/plot_quality_composite, focused report
  05_quality_score; thresholds from literature defaults or in-experiment
  QC samples (annotation QC column, ThresholdMode=qc_relative);
  non-tryptic K/R signal split into low-weight diagnostic +
  out-of-window scored metric; no external data/deps;
  test-quality-score.R covers score_curve/anchor_information_content
  (v0.10.0)

- cross-class MHC1\<-\>MHC2 contamination metric: frac_cross_class
  (fraction of peptides in the other class’s length window outside the
  current one; .cross_class_range helper; lower_better, low weight, NA
  for custom windows) + plot_cross_class_length per-sample length
  histogram with cross-class region highlighted, wired into
  qc_metrics_by_sample/quality_thresholds_default and the
  05_quality_score report (v0.11.0)

- Average +/- sd per BioReplicate: new section in 01_id_counts mirroring
  per-Condition; plot_count_mean_sd() gained group_var arg (default
  “Condition”, pass “BioReplicate”) (v0.12.0)

- “Selected peptides” report headers now show the active length window
  (e.g. “(8 to 13 AAs)”) from shortpep_range across the focused
  templates (v0.12.0)

- renamed “Proteins” ID-level headers/labels to “Parent proteins” in
  01_id_counts/02_overlaps (display only; data keys + plot axis labels
  unchanged; counts_labels display vector added alongside counts_levels)
  (v0.12.0)

- Proportion by length pulled into its own 2nd-level section in
  01_id_counts with Condition/BioReplicate/Sample tabs (was nested under
  Total-by-Condition/Sample) (v0.12.0)

- Overlap intra-Condition: added a percentage variant section in
  02_overlaps; plot_overlap_intra_condition() gained value arg (“count”
  default / “percent”) (v0.12.0)

- improve the readme: made Step 2 a bare annotation skeleton (no
  sample_list.xlsx needed; removed the duplicated get_annot_sampleid
  that also lived in Step 3, now the single optional mention); added a
  note under Step 3 that the annotation table controls inclusion (only
  listed samples are read/reported) and ordering (factor levels = CSV
  row order); added an “Edit these for your run” callout listing the
  must-change params before the Step 5 render example

- pseudochromatogram color by density: plot_pseudochromatogram() now
  fills RT bars by peptide Count (continuous viridis gradient) instead
  of per-Condition colour, keeping the facet-per-Condition layout
  (v0.13.0)

- pseudomobilogram: new plot_pseudomobilogram() (count vs invk0/1k0,
  configurable binwidth, default 0.2, bars coloured by count, faceted by
  Condition); wired into 03_lcms_qc view config (new “Pseudomobilograms”
  tab) and 00_mhc_report distribution section (all/selected) (v0.13.0)

- Peptides identified per charge, add black lines on bars:
  plot_charge_proportions() geom_bar gained color = “black” (v0.13.0)

- plot unclustered motifs from 7 to 25: motif length window extended to
  7–25 AAs (was capped at 24); section retitled “Peptide motifs (7 to 25
  AAs)” in 01_id_counts and 00_mhc_report (v0.13.0)

- add subset suffix to all the results: shared setup.Rmd (and the two
  00\_\* reports) derive result_prefix (= Subset, NULL when unset),
  passed to every write.csv_rawr()/write_input_params() and prepended to
  seq_by_condition.xlsx, so result filenames carry the subset
  (e.g. dda_all_pep_all.csv); input_params combines subset + report name
  to stay collision-free (v0.13.0)

- bigger font

- mouse MHC1 option (7 to 11 AAs): new MHCclass value `MHC1_mouse`;
  windows/palettes moved to R/report-helpers.R (mhc_length_window /
  mhc_class_palette / mhc_classes), replacing 3 duplicated lists in the
  skeletons + the copy inside .cross_class_range(); quality score
  follows (frac_9mer counts 8+9-mers with the “8/9-mer fraction” label
  and higher cut-offs, anchor scored on the dominant of the two,
  cross-class window from the 7-11 window) (v0.15.0)

- safeguard in get_annot_sampleid: warns when nothing matched (showing
  example Source_file values from both sides) and when only some rows
  matched (naming the dropped ones); new keep_all = TRUE argument
  left-joins so no annotation row is lost (v0.15.0)

- fixed combn(conditions, 2) aborting every report with a single
  Condition: new exported condition_pairs() (empty list for 1 Condition,
  self = TRUE for the overlap-matrix diagonal) used by the shared
  setup + 00_mhc_report/00_mhc_upsets/02_overlaps; guarded by an
  end-to-end single-Condition render test (v0.15.0)

- test mode for combined exports: files are read in full and reduced to
  ~100 rows PER RUN (subsample_testmode() in R/utils-loaders.R, run
  column auto-detected from Run/Spectrum) instead of the first 100 lines
  of the file, so every run/Condition/replicate survives; wrong “first
  50 lines” warning fixed (v0.15.0)

- safeguard when all area = 0: get_mat_log2area() returns a 0 x n matrix
  with a warning instead of erroring in select(all_of()), and the
  correlation chunks of 04_quant/00_mhc_report test for the empty/all-NA
  case before calling cor() (which errors with ‘x’ is empty) and before
  computing the colour limits (v0.15.0)

- homogenized sample annotation tables across software: canonical
  `Sample_folder` column accepted by read_annot() and mirrored into
  Sample_fp (verbatim) / Sample_peaks (PEAKS-normalized) so the loaders
  are untouched and legacy CSVs still load;
  get_annot_fragpipe()/get_annot_diann() emit Sample_folder and PEAKS
  gained get_annot_peaks() (v0.15.0)

- advanced statistics / quantification report: new `06_quant_stats`
  template + `R/quant-stats.R` engine (build_quant_matrix, filter_quant,
  normalize_quant, impute_quant, test_differential, test_detection,
  combine_quant_results, summarise_significant, permanova_condition)
  comparing peptide Area between Conditions with limma moderated t
  (Welch t fallback; limma in Suggests) + Fisher presence/absence track
  for condition-exclusive ligands; includes data completeness plots,
  normalization diagnostics, dynamic range, PCA, heatmaps with and
  without clustering, volcano/MA/p-value plots and significance
  summaries, plus an in-report “Methods & justification” section
  (v0.14.0)

- data completeness plots: plot_completeness() (per unit / per
  feature) + plot_missing_heatmap() presence-absence map, in
  06_quant_stats (v0.14.0)

- quantitative report heatmap with and without clustering, dynamic
  range, volcano plots: plot_quant_heatmap(cluster = TRUE/FALSE),
  plot_dynamic_range(), plot_volcano()/plot_ma(), all in 06_quant_stats
  (v0.14.0)

- fixed run_howmahico_report(“05_quality_score”) being unreachable
  (template documented but missing from the match.arg choices); 05 and
  06 registered + regression guard test that every shipped template dir
  is offered (v0.14.0)

- peptide physicochemical properties report: new `07_pepchem` template +
  `R/pepchem.R` engine (peptide_properties, pepchem_properties,
  aa_composition, aa_position_frequency, pepchem_by_sample,
  summarise_pepchem, aggregate_pepchem, cliffs_delta, compare_pepchem,
  compare_aa_frequency) comparing amino-acid composition (overall / per
  sample / enrichment vs. the pooled composition), per-position residue
  frequency (dominant length + N-/C-terminal profile across all lengths)
  and per-peptide descriptors (GRAVY, pI, charge, MW, Boman, hydrophobic
  moment, instability/aliphatic index, AA class fractions) between
  Conditions. Descriptors are summarised per SAMPLE and then tested
  across samples (Kruskal-Wallis + pairwise Wilcoxon, BH, MedianDiff +
  Cliff’s delta), with a pooled peptide-level track reported alongside
  as explicitly descriptive; new plots plot_aa_composition /
  plot_aa_position_heatmap / plot_property_distribution /
  plot_property_sample_summary / plot_property_effectsize; new
  dependency Peptides (CRAN, Rcpp only) in Imports, justified as the
  canonical GRAVY implementation. Position-within-the-protein moved to
  standby (v0.16.0)
