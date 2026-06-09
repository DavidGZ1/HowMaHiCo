# plans\_dgz.md - HowMaHiCo

## What this is

Plans by DGZ to improve HowMaHiCo.

## To do

## In standby

Do not consider these in the planning, until they are moved to "to do"

* one single parser function





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
* 

