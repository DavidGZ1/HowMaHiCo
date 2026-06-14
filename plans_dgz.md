# plans\_dgz.md - HowMaHiCo

## What this is

Plans by DGZ to improve HowMaHiCo.

Instructions: when prompted, you can read this file and provide a plan to do the pending tasks in "to do". When something is done, move it to the end of "Done". Do not consider the points in "In standby", until they are moved to "to do"

## To do
* Rename 01_mhc_report to 00_mhc_report
* Rename 01_mhc_upsets to 00_mhc_upsets
* In lcms_qc, Peptide ID distribution across RT, 1/k0 and m/z, change the way chunks are plotted, use the looped structure used for other sections, with results = “asis”


## In standby

* one single parser function
* 2do by me, check Overlap intra-Condition seems to be showing peptides in sequences, and sequences+proteins in proteins
* reorder plots in a way that makes more sense
* add functionality for peaks Xpro
* homogenize sample annotation tables across software
* Overlap intra-Condition (across replicates) is currently showing absolute count numbers. Add another section showing similar plots but with y axis as percentages.
* Plan an advanced quantification report. Use Limma for the normalization and statisticla testing.



## Done

* deal with code possibly buried in a folder, e.g. as option in setup:

opts\_knit$set(root.dir = normalizePath(".."))

* libraries not being loaded: kableExtra, ggpubr, viridis, plotly, openxlsx, dplyr
* standardize function names:

  * loaders as read\_software for individual files and read\_software\_batch for multiple inputs
  * read\_software\_batch include the option to provide the annotation and only read files referenced in the table, or a simple vector
  * also rename the parse functions
* I ran a test in a parallel session. There is an error on chunk 20, rownames\_to\_column function was not found. library(tibble) is missing.
* convert 00\_extract\_sample\_info\_fragpipe to functions in loaders-fragpipe
* I moved the original folders and their contents to example. Check that it doesn't break anything, and also add that folder itself to .gitignore
* add :

get\_report\_template <- function(file = "HowMaHiCoReportTemplate", edit = FALSE, create\_dir = FALSE) {

&#x20; rmarkdown::draft(file = file,

&#x20;                  template = "howmahico-report",

&#x20;                  edit = edit,

&#x20;                  package = "HowMaHiCo",

&#x20;                  create\_dir = create\_dir)

}

* correct mentions of "suffix" to "subset"
* check if it is possible to simplify the params entered in howmahico-report, provide a plan
* the batch readers currently read all the files in the data folder, then drop what is not in the annotation table. provide a plan to only read what is needed.
* read\_peaks\_batch has to be split because it currently includes the parser inside
* update readme and documentation following the example in example/0\\\_code/00\\\_pipeline\\\_example
* rename templates howmahico-report to 01\\\_mhc\\\_report, and howmahico-upsets to 02\\\_mhc\\\_upsets, the required functions and documentation
* implement default modes for:

  * MHC1, ShortPeptideLengthMin = 8, ShortPeptideLengthMax = 13
  * MHC2, ShortPeptideLengthMin = 12, ShortPeptideLengthMax = 25
* standardize report title by generating it programmatically. Include: template name, SampleSet, subset, MHCclass, date
* Adapt color/fill palette for all the plots where the shortpep\_range is used as aesthetic. Use manual scale instead of viridis. If MHCclass = MHC1, use c("#fde725", "#440154"); If MHCclass = MHC2, use c("#21918c", "#440154"). If custom lengths, use the same palette as MHC1
* in the pipeline (in example and also documentation), include a step to check if all the files named in the annotation table exist. print the list of files missing, and then stop with an error.
* in 01\_mhc\_report, add a section replicating section "## Total by Condition", but the x axis should be each sample
* homogenize the theme across the plotting functions: created theme\_howmahico, applied to all plotting functions and report skeletons. Also homogenized font sizes for labels, axes, and annotations.
* homogenize fig.width across all the chunks to 8.
* add names to chunks
* peptide length distribution, create a simpler function without the boxplot on top. This should facilitate using facet instead of ggarrange, include the option to color bars using two colors, based on the MHCclass. Also include option to show density or absolute numbers. In report, include both versions as sub-sections within a .{tabset}
* add Proportion by length at sample level to ## Total by Sample
* some plots use scale\_y\_continous with fixed breaks and labels. Changed to n.breaks = 5 in plot\_bp\_count\_length, plot\_count\_mean\_sd, plot\_overlap\_intra\_condition
* Peptide motifs: show up to length = 24 (was 22)
* # Identification counts ## Average +/- sd: all peptides and selected peptides shown separately in nested tabsets
* "# Peptide ID distribution across RT, 1/k0 and m/z": extracted to plot\_pseudochromatogram() and plot\_2d\_distribution(); skeleton simplified to 1-2 lines per chunk
* 2do by me,Identification counts, average +/-sd, split into individual plots for each length
* add to the readme as optional subpoint in complete the annotation csv: complete the annotation table with the Sample_ID from the Hystar sample list using get_annot_sampleid
* de-vendor get_dirs_index_peaks: removed the vendored/deltaProtR provenance, renamed R/vendored-deltaprotr.R to R/loaders-peaks-dirs.R, converted its pipes to |> (v0.3.0)
* unify the two report templates (01_mhc_report, 02_mhc_upsets skeleton.Rmd) on the native |> pipe (181 %>% converted; verified via knitr::purl + parse) (v0.3.0)
* 2do by me change purple color of length plots to a dimmer one
* Overlap intra-Condition (across replicates), split into individual plots for each length: plot_overlap_intra_condition() refactored to single-plot (df, id_col, title); report section now All peptides / Selected peptides nested tabsets (v0.5.0)
* Peptides identified per charge +1 to +4, one plot for all peptides (pep_all) and one for selected length (pep_short), shown in an All / Selected tabset (v0.5.0)
* multi-report framework instead of one big report: exported build_pep_all() (parse+cache step), shared inst/rmarkdown/shared/setup.Rmd child, and four focused templates 03_id_counts / 04_overlaps / 05_lcms_qc / 06_quant rendered against the cached pep_all; 01_mhc_report kept unchanged for retrocompatibility (v0.6.0)
* PTM profile moved from 05_lcms_qc to 03_id_counts, and extended to show all peptides (pep_all) alongside selected (pep_short) in an All/Selected tabset (v0.6.1)

