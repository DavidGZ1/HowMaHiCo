# plans\_dgz.md - HowMaHiCo

## What this is

Plans by DGZ to improve HowMaHiCo.

Instructions: when prompted, you can read this file and provide a plan to do the pending tasks in "to do". When something is done, move it to the end of "Done". Do not consider the points in "In standby", until they are moved to "to do"

## To do

* in the rmd templates, add a boolean option (TRUE/FALSE) for InteractivePlots. If true, all the plots compatible should be plotted using ggplotly.





## In standby
* homogenize sample annotation tables across software
* For PTM plots, translate unimod code into modification name
* Calculate an fdr for length distribution. What’s the probability of detecting the length distribution vs. the background proteome?
* add other proporties such as GRAVY
* add data completeness plots
* for quantitative report: heatmap with and without clustering, dynamic range, volcano plots
* Total by Condition /BioReplicate / Sample in tabs

### to be done by DGZ 
* Check and complete glosary
* check/add functionality for peaks Xpro
* pseudomobilogram
* pseudochromatogram color by density
* Peptides identified per charge, add black lines on bars
* bigger font
* plot unclustered motifs from 7 to 25
* 2do by me, check Overlap intra-Condition seems to be showing peptides in sequences, and sequences+proteins in proteins - corrected in the individual reports, but not in the legacy main report
* reorder plots in a way that makes more sense
* manual checking and re-writing text by me



## advanced plans

* include MaHiCoBench dataset for LFQbench-style plots
* Plan an advanced quantification report. Use Limma for the normalization and statistical testing.
* Dataset: use the JY hla1 and hla2 from Annica and Julian
* Simple summary of HowMaHiCo ala HowDirty
* Push a v1 and publication with this dataset before adding many more functionalities
* Maybe switch TechRep to InjRep
* Standardize headers, include a function to convert from old to new headers
* Wheremahico = peptide distribution in the protein. Add a widget to show location of peptides in specific protein
* Whichmahico = detect which alleles
* Ismahico= binding prediction
* HowConta = summary of common contaminants
* Another idea: hla allotyping from hla peptides in the ip data



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
* add to the readme as optional subpoint in complete the annotation csv: complete the annotation table with the Sample\_ID from the Hystar sample list using get\_annot\_sampleid
* de-vendor get\_dirs\_index\_peaks: removed the vendored/deltaProtR provenance, renamed R/vendored-deltaprotr.R to R/loaders-peaks-dirs.R, converted its pipes to |> (v0.3.0)
* unify the two report templates (01\_mhc\_report, 02\_mhc\_upsets skeleton.Rmd) on the native |> pipe (181 %>% converted; verified via knitr::purl + parse) (v0.3.0)
* 2do by me change purple color of length plots to a dimmer one
* Overlap intra-Condition (across replicates), split into individual plots for each length: plot\_overlap\_intra\_condition() refactored to single-plot (df, id\_col, title); report section now All peptides / Selected peptides nested tabsets (v0.5.0)
* Peptides identified per charge +1 to +4, one plot for all peptides (pep\_all) and one for selected length (pep\_short), shown in an All / Selected tabset (v0.5.0)
* multi-report framework instead of one big report: exported build\_pep\_all() (parse+cache step), shared inst/rmarkdown/shared/setup.Rmd child, and four focused templates 03\_id\_counts / 04\_overlaps / 05\_lcms\_qc / 06\_quant rendered against the cached pep\_all; 01\_mhc\_report kept unchanged for retrocompatibility (v0.6.0)
* PTM profile moved from 05\_lcms\_qc to 03\_id\_counts, and extended to show all peptides (pep\_all) alongside selected (pep\_short) in an All/Selected tabset (v0.6.1)
* renumbered all report templates: 01\_mhc\_report->00\_mhc\_report, 02\_mhc\_upsets->00\_mhc\_upsets, 03\_id\_counts->01\_id\_counts, 04\_overlaps->02\_overlaps, 05\_lcms\_qc->03\_lcms\_qc, 06\_quant->04\_quant (v0.7.0)
* lcms\_qc RT/1k0/m\_z distribution section rewritten to a single looped results='asis' chunk (config list of views x peptide sets) instead of 8 hand-written chunks (v0.7.0)
* fixed "Duplicate chunk label 'setup'" parse error in the focused reports: shared setup.Rmd had a fenced r-chunk example inside its leading HTML comment (knitr parses chunks even in comments -> recursive re-include); comment is now prose + regression guard test (v0.7.1)
* focused reports gained PepAllSource param (cached / rda / build) so each can load the default cache, load an explicit .rda (PepAllFile), or self-build from raw results via build\_pep\_all(); default = cached = prior behavior (v0.8.0)
* added simulated FragPipe data (inst/extdata/sim\_fragpipe\_dda, moved out of data/) + test-sim-fragpipe.R: build\_pep\_all assertion + first end-to-end render test of a focused report (v0.8.0)
* unified parser using dictionaries with option to enter a custom entry from other software: dictionary-driven parse\_unified() + read\_custom\_batch() + annotate\_unified() + read\_dictionary()/get\_dictionary\_template(), wired into build\_pep\_all(software="custom", dictionary=...); YAML dictionaries in inst/extdata/dictionaries (custom\_template + fragpipe/diann/peaks reference); built-in loaders untouched; test-parse-unified.R round-trips against the FragPipe loader (v0.9.0)
* immunopeptidomics sample quality score (HowDirty-inspired, inverted): R/quality-score.R (score\_sample\_quality + qc\_metrics\_by\_sample + anchor\_information\_content + score\_curve + quality\_thresholds\_default + calibrate\_thresholds\_from\_qc), plot\_quality\_heatmap/plot\_quality\_composite, focused report 05\_quality\_score; thresholds from literature defaults or in-experiment QC samples (annotation QC column, ThresholdMode=qc\_relative); non-tryptic K/R signal split into low-weight diagnostic + out-of-window scored metric; no external data/deps; test-quality-score.R covers score\_curve/anchor\_information\_content (v0.10.0)
* cross-class MHC1<->MHC2 contamination metric: frac\_cross\_class (fraction of peptides in the other class's length window outside the current one; .cross\_class\_range helper; lower\_better, low weight, NA for custom windows) + plot\_cross\_class\_length per-sample length histogram with cross-class region highlighted, wired into qc\_metrics\_by\_sample/quality\_thresholds\_default and the 05\_quality\_score report (v0.11.0)
* Average +/- sd per BioReplicate: new section in 01\_id\_counts mirroring per-Condition; plot\_count\_mean\_sd() gained group\_var arg (default "Condition", pass "BioReplicate") (v0.12.0)
* "Selected peptides" report headers now show the active length window (e.g. "(8 to 13 AAs)") from shortpep\_range across the focused templates (v0.12.0)
* renamed "Proteins" ID-level headers/labels to "Parent proteins" in 01\_id\_counts/02\_overlaps (display only; data keys + plot axis labels unchanged; counts\_labels display vector added alongside counts\_levels) (v0.12.0)
* Proportion by length pulled into its own 2nd-level section in 01\_id\_counts with Condition/BioReplicate/Sample tabs (was nested under Total-by-Condition/Sample) (v0.12.0)
* Overlap intra-Condition: added a percentage variant section in 02\_overlaps; plot\_overlap\_intra\_condition() gained value arg ("count" default / "percent") (v0.12.0)

