# plans\_dgz.md - HowMaHiCo

## What this is

Plans by DGZ to improve HowMaHiCo.

Instructions: when prompted, you can read this file and provide a plan to do the pending tasks in "to do". When something is done, move it to the end of "Done". Do not consider the points in "In standby", until they are moved to "to do"

## To do

* 





## In standby

* one single parser function
* adapt fig.width and fig.height in function of the number of the number of facets, or variables
* \#2do by me, check Overlap intra-Condition seems to be showing peptides in sequences, and sequences+proteins in proteins
* \#2do by me,Identification counts, average +/-sd, split into individual plots for each length
* reorder plots in a way that makes more sense



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
