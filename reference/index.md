# Package index

## Render reports

Entry points that build the cached pep_all table and render the
parameterized QC report templates (00_mhc_report all-in-one, or the
focused 01-07 reports)

- [`build_pep_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_pep_all.md)
  :

  Build (and optionally cache) the unified `pep_all` table from raw
  search output

- [`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md)
  : Render a HowMaHiCo QC report from the installed package templates

- [`derive_filtered_annotation()`](https://davidgz1.github.io/HowMaHiCo/reference/derive_filtered_annotation.md)
  : Derive a Condition-filtered copy of a sample annotation file

- [`get_report_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_report_template.md)
  : Get the HowMaHiCo templates

- [`get_pipeline_script()`](https://davidgz1.github.io/HowMaHiCo/reference/get_pipeline_script.md)
  : Copy the guided analysis-pipeline script to the working directory

## Annotation

Read, validate, display, and auto-generate sample annotation tables

- [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md)
  : Read, validate, and reformat a sample annotation table
- [`print_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/print_annot.md)
  : Render an annotation table as an interactive HTML datatable
- [`get_annot_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_fragpipe.md)
  : Auto-generate a skeleton annotation table from FragPipe psm.tsv
  files
- [`get_annot_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_diann.md)
  : Auto-generate a skeleton annotation table from DIA-NN report.tsv
  files
- [`get_annot_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_peaks.md)
  : Auto-generate a skeleton annotation table from a PEAKS export folder
- [`get_annot_sampleid()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_sampleid.md)
  : Enrich an annotation table with Sample_ID from a Bruker HyStar
  sample list

## Report helpers

Shared settings the report templates derive from their params: the MHC
length window and palette, and the Condition pairs to compare

- [`mhc_length_window()`](https://davidgz1.github.io/HowMaHiCo/reference/mhc_length_window.md)
  : Peptide-length window of an MHC class
- [`mhc_class_palette()`](https://davidgz1.github.io/HowMaHiCo/reference/mhc_class_palette.md)
  : Two-colour fill palette of an MHC class
- [`mhc_classes()`](https://davidgz1.github.io/HowMaHiCo/reference/mhc_classes.md)
  : Names of the built-in MHC classes
- [`condition_pairs()`](https://davidgz1.github.io/HowMaHiCo/reference/condition_pairs.md)
  : All pairwise Condition comparisons
- [`provider_line()`](https://davidgz1.github.io/HowMaHiCo/reference/provider_line.md)
  : Provider sentence of a report header

## Data loaders

Software-specific loader families that converge on the unified `pep_all`
schema

- [`read_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/read_fragpipe.md)
  :

  Read one FragPipe `psm.tsv` or DIA-NN `report.tsv` file

- [`read_fragpipe_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_fragpipe_batch.md)
  :

  Batch-read FragPipe `psm.tsv` files and merge them

- [`parse_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_fragpipe.md)
  :

  Parse raw FragPipe PSM results into `pep_all` format

- [`annotate_fragpipe()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_fragpipe.md)
  : Join parsed FragPipe results to the sample annotation table

- [`read_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/read_diann.md)
  :

  Read one DIA-NN `report.tsv` file

- [`read_diann_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_diann_batch.md)
  :

  Batch-read DIA-NN `report.tsv` files and merge them

- [`parse_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_diann.md)
  :

  Parse raw DIA-NN report results into `pep_all` format

- [`annotate_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_diann.md)
  : Join parsed DIA-NN results to the sample annotation table

- [`read_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks.md)
  :

  Read one PEAKS `peptide.csv` export into long format

- [`read_peaks_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_peaks_batch.md)
  : Batch-read PEAKS export folders and merge them into raw long format

- [`parse_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_peaks.md)
  :

  Parse raw PEAKS results into `pep_all` format

- [`annotate_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_peaks.md)
  : Join parsed PEAKS results to the sample annotation table

## Custom (dictionary-driven) parsing

The `software = "custom"` path: ingest a tabular export from a tool with
no built-in loader by editing a YAML dictionary instead of writing R
code.

- [`get_dictionary_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dictionary_template.md)
  : Copy the custom-parser dictionary template to the working directory

- [`read_dictionary()`](https://davidgz1.github.io/HowMaHiCo/reference/read_dictionary.md)
  : Read and validate a HowMaHiCo parser dictionary

- [`read_custom_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/read_custom_batch.md)
  : Batch-read a generic per-sample tabular export

- [`parse_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_unified.md)
  :

  Parse a raw search-engine export into `pep_all` via a dictionary

- [`annotate_unified()`](https://davidgz1.github.io/HowMaHiCo/reference/annotate_unified.md)
  : Join a dictionary-parsed table to the sample annotation

## Checks

Guard against clobbering existing output and summarise global ID
composition

- [`check_file_exists()`](https://davidgz1.github.io/HowMaHiCo/reference/check_file_exists.md)
  : Check whether a single output file already exists
- [`check_output_exists()`](https://davidgz1.github.io/HowMaHiCo/reference/check_output_exists.md)
  : Check whether any of the report's standard output files already
  exist
- [`check_ids_global()`](https://davidgz1.github.io/HowMaHiCo/reference/check_ids_global.md)
  : Total ID counts split by protein/decoy/contaminant assignment

## Counting & overlap analysis

Tabulate ID counts, charge/area summaries, sequence lists, and
cross-condition overlaps

- [`count_ids()`](https://davidgz1.github.io/HowMaHiCo/reference/count_ids.md)
  : Count distinct peptides, sequences, and proteins

- [`count_ids_condition_bylengthrange()`](https://davidgz1.github.io/HowMaHiCo/reference/count_ids_condition_bylengthrange.md)
  :

  ID counts and proportions by `Length_range` and `Condition`

- [`count_ids_by()`](https://davidgz1.github.io/HowMaHiCo/reference/count_ids_by.md)
  : Wide table of peptide identifications by an arbitrary grouping

- [`get_charge_group()`](https://davidgz1.github.io/HowMaHiCo/reference/get_charge_group.md)
  :

  Classify charge states into `+1`/`+2`/`>= +3` groups

- [`get_proportion_charge()`](https://davidgz1.github.io/HowMaHiCo/reference/get_proportion_charge.md)
  : Proportions of each charge group within a count table

- [`get_mat_log2area()`](https://davidgz1.github.io/HowMaHiCo/reference/get_mat_log2area.md)
  :

  Build a `Log2Area` matrix for clustering/heatmaps/correlation

- [`summarise_area()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_area.md)
  : Per-peptide Area mean/sd/%CV summary by group

- [`list_sequences()`](https://davidgz1.github.io/HowMaHiCo/reference/list_sequences.md)
  : List unique peptide sequences per group

- [`count_intersect()`](https://davidgz1.github.io/HowMaHiCo/reference/count_intersect.md)
  : Count distinct elements shared between two conditions

- [`count_merged()`](https://davidgz1.github.io/HowMaHiCo/reference/count_merged.md)
  : Count distinct elements across the union of two conditions

- [`count_samples_patients()`](https://davidgz1.github.io/HowMaHiCo/reference/count_samples_patients.md)
  : Combined per-Patient/Sample_type/Condition sample-and-patient count
  summary

- [`select_unique()`](https://davidgz1.github.io/HowMaHiCo/reference/select_unique.md)
  : Select distinct rows on a subset of columns

- [`filter_unique()`](https://davidgz1.github.io/HowMaHiCo/reference/filter_unique.md)
  : Filter rows and drop to distinct/unused-level state

## Plotting

QC plots covering ID size/charge distributions, overlaps, motifs, and
correlation

- [`plot_peplength_dens()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_peplength_dens.md)
  : Peptide length distribution: boxplot + density histogram

- [`plot_peplength_hist()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_peplength_hist.md)
  : Peptide length histogram faceted by Condition

- [`plot_pepmass()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pepmass.md)
  : Peptide mass distribution: boxplot + density histogram with apex
  annotation

- [`plot_pepmz()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pepmz.md)
  : Peptide m/z distribution: boxplot + density histogram with apex
  annotation

- [`plot_bp_count_length()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_bp_count_length.md)
  : Stacked bar chart of total ID counts per Condition, split by length
  range

- [`plot_count_mean_sd()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_count_mean_sd.md)
  : Mean ± SD barplot of ID counts per Condition, faceted by length
  range

- [`plot_prop_length_condition()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_prop_length_condition.md)
  :

  Stacked bar chart of peptide proportions by `Length_range` and
  `Condition`

- [`plot_charge_proportions()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_charge_proportions.md)
  : Stacked bar chart of charge-state proportions by group

- [`plot_overlap_intra_condition()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_overlap_intra_condition.md)
  : Overlap barplot for one ID level

- [`plot_upset()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_upset.md)
  : UpSet plot of overlap between groups for a given variable

- [`plot_upset_batch()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_upset_batch.md)
  : Batch of UpSet plots across several variables

- [`plot_pseudochromatogram()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pseudochromatogram.md)
  : Peptide ID pseudochromatogram: count vs RT, faceted by Condition

- [`plot_pseudomobilogram()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pseudomobilogram.md)
  : Peptide ID pseudomobilogram: count vs 1/k0, faceted by Condition

- [`plot_2d_distribution()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_2d_distribution.md)
  : 2D binned heatmap for any two continuous peptide properties

- [`plot_violin_areacv()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_violin_areacv.md)
  : Violin + boxplot of Area %CV by group

- [`plot_qc_box()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_qc_box.md)
  : Boxplot of Score or mass error per Condition and charge

- [`plot_qc_violin()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_qc_violin.md)
  : Violin + overlaid boxplot of Score or mass error per Condition and
  charge

- [`plot_corr()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_corr.md)
  : Pearson correlation heatmap of log2(Area)

- [`plot_ptm_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_ptm_heatmap.md)
  : Heatmap of PTM counts or proportions for length-filtered peptides

- [`ggseqlogo_bylength()`](https://davidgz1.github.io/HowMaHiCo/reference/ggseqlogo_bylength.md)
  : Sequence motif logo for peptides of a given length

- [`theme_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/theme_rawr.md)
  : HowMaHiCo's shared ggplot theme

- [`theme_howmahico()`](https://davidgz1.github.io/HowMaHiCo/reference/theme_howmahico.md)
  : HowMaHiCo's unified ggplot theme

## Sample quality score

Per-sample immunopeptidomics quality score behind the 05_quality_score
report: raw signals (length-window fidelity, canonical-length dominance,
anchor-motif clarity, non-tryptic specificity, charge plausibility,
depth, mass accuracy, cross-class contamination), the threshold model,
and the weighted 0-100 composite.

- [`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md)
  : Score immunopeptidomics samples for overall quality
- [`qc_metrics_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/qc_metrics_by_sample.md)
  : Raw per-sample immunopeptidomics quality metrics
- [`anchor_information_content()`](https://davidgz1.github.io/HowMaHiCo/reference/anchor_information_content.md)
  : Per-position anchor information content of equal-length peptides
- [`score_curve()`](https://davidgz1.github.io/HowMaHiCo/reference/score_curve.md)
  : Map a raw metric value to a 0-100 quality sub-score
- [`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md)
  : Default quality-score thresholds and weights
- [`calibrate_thresholds_from_qc()`](https://davidgz1.github.io/HowMaHiCo/reference/calibrate_thresholds_from_qc.md)
  : Derive QC-relative thresholds from tagged quality-control samples
- [`plot_quality_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_quality_heatmap.md)
  : Traffic-light heatmap of per-sample quality sub-scores
- [`plot_quality_composite()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_quality_composite.md)
  : Per-sample composite quality-score bar chart
- [`plot_cross_class_length()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_cross_class_length.md)
  : Per-sample peptide-length histogram highlighting cross-class
  contamination

## Advanced quantification & statistics

Build the quantitative matrix and compare peptide Area between
Conditions (filtering, normalization, imputation, limma moderated t /
Welch t, Fisher presence-absence, PERMANOVA) plus the plots of the
06_quant_stats report

- [`build_quant_matrix()`](https://davidgz1.github.io/HowMaHiCo/reference/build_quant_matrix.md)
  :

  Build a feature x unit log2(Area) matrix from `pep_all`

- [`filter_quant()`](https://davidgz1.github.io/HowMaHiCo/reference/filter_quant.md)
  : Filter a quantitative matrix to testable features

- [`normalize_quant()`](https://davidgz1.github.io/HowMaHiCo/reference/normalize_quant.md)
  : Between-sample normalization of a log2 intensity matrix

- [`impute_quant()`](https://davidgz1.github.io/HowMaHiCo/reference/impute_quant.md)
  : Left-censored imputation of missing quantitative values

- [`test_differential()`](https://davidgz1.github.io/HowMaHiCo/reference/test_differential.md)
  : Differential abundance between conditions

- [`test_detection()`](https://davidgz1.github.io/HowMaHiCo/reference/test_detection.md)
  : Presence/absence test between conditions (Fisher exact)

- [`combine_quant_results()`](https://davidgz1.github.io/HowMaHiCo/reference/combine_quant_results.md)
  : Combine the quantitative and presence/absence tracks

- [`summarise_significant()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_significant.md)
  : Count significant features per contrast

- [`permanova_condition()`](https://davidgz1.github.io/HowMaHiCo/reference/permanova_condition.md)
  : Global permutation test of condition separation (PERMANOVA)

- [`plot_completeness()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_completeness.md)
  : Data completeness of a quantitative matrix

- [`plot_missing_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_missing_heatmap.md)
  : Presence/absence map of a quantitative matrix

- [`plot_intensity_dist()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_intensity_dist.md)
  : Intensity distribution per unit (normalization diagnostic)

- [`plot_dynamic_range()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_dynamic_range.md)
  : Dynamic range (rank-abundance) per condition

- [`plot_pca()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pca.md)
  : Principal component analysis of a quantitative matrix

- [`plot_quant_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_quant_heatmap.md)
  : Heatmap of a quantitative matrix, clustered or in annotation order

- [`plot_volcano()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_volcano.md)
  : Volcano plot of a differential-abundance result

- [`plot_ma()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_ma.md)
  : MA plot of a differential-abundance result

- [`plot_pvalue_hist()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_pvalue_hist.md)
  : P-value histogram (test calibration diagnostic)

- [`plot_sig_summary()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_sig_summary.md)
  : Significant-feature counts per contrast

## Physicochemical properties

Peptide-chemistry engine behind the 07_pepchem report: amino-acid
composition, per-position residue frequency and per-peptide descriptors
(GRAVY, pI, charge, …), summarised per sample and compared between
Conditions.

- [`peptide_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/peptide_properties.md)
  : Per-sequence physicochemical descriptors
- [`pepchem_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/pepchem_properties.md)
  : Descriptor columns of a property set
- [`aa_composition()`](https://davidgz1.github.io/HowMaHiCo/reference/aa_composition.md)
  : Position-independent amino-acid composition
- [`aa_position_frequency()`](https://davidgz1.github.io/HowMaHiCo/reference/aa_position_frequency.md)
  : Per-position amino-acid frequency
- [`pepchem_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/pepchem_by_sample.md)
  : Per-sample peptide physicochemical descriptors
- [`summarise_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/summarise_pepchem.md)
  : Summarise peptide descriptors within a group
- [`aggregate_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/aggregate_pepchem.md)
  : Aggregate per-sample descriptor summaries to Conditions
- [`cliffs_delta()`](https://davidgz1.github.io/HowMaHiCo/reference/cliffs_delta.md)
  : Cliff's delta effect size
- [`compare_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_pepchem.md)
  : Compare peptide descriptors between Conditions
- [`compare_aa_frequency()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_aa_frequency.md)
  : Compare amino-acid frequencies between Conditions
- [`plot_aa_composition()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_aa_composition.md)
  : Amino-acid composition across groups
- [`plot_aa_position_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_aa_position_heatmap.md)
  : Per-position amino-acid frequency heatmap
- [`plot_property_distribution()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_property_distribution.md)
  : Distribution of one peptide descriptor across Conditions
- [`plot_property_sample_summary()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_property_sample_summary.md)
  : Per-Condition mean +/- sd of a descriptor across samples
- [`plot_property_effectsize()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_property_effectsize.md)
  : Effect sizes of the between-condition comparison

## Export & I/O helpers

Write report outputs (plots, csvs, render parameters) to disk

- [`ggsave_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/ggsave_rawr.md)
  : Save a ggplot to a folder, skipping plots that were never built
- [`ggprint_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/ggprint_rawr.md)
  : Print a plot, skipping ones that were never built
- [`write.csv_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/write.csv_rawr.md)
  : Write a data frame to csv, named after the variable that was passed
  in
- [`write_input_params()`](https://davidgz1.github.io/HowMaHiCo/reference/write_input_params.md)
  : Write a report's render parameters to csv

## Package overview

- [`HowMaHiCo`](https://davidgz1.github.io/HowMaHiCo/reference/HowMaHiCo-package.md)
  [`HowMaHiCo-package`](https://davidgz1.github.io/HowMaHiCo/reference/HowMaHiCo-package.md)
  : HowMaHiCo: LC-Immunopeptidomics QC Reporting Workflow
