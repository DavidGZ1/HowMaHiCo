# Package index

## Render reports

Entry points that build the cached pep_all table and render the
parameterized QC report templates (00_mhc_report all-in-one, or the
focused 01-04 reports)

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
- [`get_annot_sampleid()`](https://davidgz1.github.io/HowMaHiCo/reference/get_annot_sampleid.md)
  : Enrich an annotation table with Sample_ID from a Bruker HyStar
  sample list

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
