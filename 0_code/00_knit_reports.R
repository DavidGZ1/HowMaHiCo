# knit reports, useful when multiple reports needed


library(rmarkdown)
library(tidyverse)
# getwd()

# generate JY and plasma annotation tables (run once only)

read.csv(file.path("1_documentation", "sample_annotation_dda_all.csv")) %>%
  filter(grepl("JY", Condition)) %>%
  write.csv(file.path("1_documentation", "sample_annotation_dda_jy.csv"), row.names = FALSE)

read.csv(file.path("1_documentation", "sample_annotation_dda_all.csv")) %>%
  filter(grepl("Plasma", Condition)) %>%
  write.csv(file.path("1_documentation", "sample_annotation_dda_plasma.csv"), row.names = FALSE)

read.csv(file.path("1_documentation", "sample_annotation_dia_all.csv")) %>%
  filter(grepl("JY", Condition)) %>%
  write.csv(file.path("1_documentation", "sample_annotation_dia_jy.csv"), row.names = FALSE)

read.csv(file.path("1_documentation", "sample_annotation_dia_all.csv")) %>%
  filter(grepl("Plasma", Condition)) %>%
  write.csv(file.path("1_documentation", "sample_annotation_dia_plasma.csv"), row.names = FALSE)


# Report 01 ------ 

## dda_all
render(
  input = file.path("0_code", "01_report_main_template.Rmd"),
  output_file = "../01_report_main__hla1_dda_all.html",
  params = list(Title = "Report: MHC1p evaluation - MEGF_035_K251128_hla1_dda_all",
                SampleSet = "MEGF_035_K251128",
                DataAnalysisNames = "MF, DGZ",
                WetLabNames = "MF",
                AnnotationFile = "sample_annotation_dda_all.csv", # Samples Annotation file in /1_documentation
                Subset = "dda_all", # subset name, is added as prefix to file names and used to creat subfolders for results and figures
                FolderData = "2_data", #for subfolders use "/"
                FolderResults = "3_results",
                FolderFigures = "4_figures",
                Instrument = "tims_tof", #faims_orbi, orbi
                Software = "fragpipe_dda_combined", # options = fragpipe_dda_individual, fragpipe_dda_combined,peaks_xpro, diann; to be added =  peaks_11
                ShortPeptideLenghtMin = 8,
                ShortPeptideLenghtMax = 13,
                PlotTextLabelSize = 1.6,
                TestMode = FALSE, # if TRUE, only first 100 lines from each file will be loaded; Warning = may mess up correlation plots
                PlotsInteractive = FALSE, #TRUE = interactive in html, FALSE = static
                ResultsOverwrite = TRUE, # FALSE throws error when output files already exist to avoid overwriting
                PlotsSave = FALSE, #Saves all the plots as .png
                CsvSave = FALSE, # TRUE = saves all intermediary csvs, FALSE = saves only essential
                TestStats = FALSE #Performs Anova and T-test to compare conditions TRUE or FALSE)
  )
)

## dia_all
render(
  input = file.path("0_code", "01_report_main_template.Rmd"),
  output_file = "../01_report_main__hla1_dia_all.html",
  params = list(Title = "Report: MHC1p evaluation - MEGF_035_K251128_hla1_dia_all",
                SampleSet = "MEGF_035_K251128",
                DataAnalysisNames = "MF, DGZ",
                WetLabNames = "MF",
                AnnotationFile = "sample_annotation_dia_all.csv", # Samples Annotation file in /1_documentation
                Subset = "dia_all", # subset name, is added as prefix to file names and used to creat subfolders for results and figures
                FolderData = "2_data", #for subfolders use "/"
                FolderResults = "3_results",
                FolderFigures = "4_figures",
                Instrument = "tims_tof", #faims_orbi, orbi
                Software = "diann", # options = fragpipe_dda_individual, fragpipe_dda_combined,peaks_xpro, diann; to be added =  peaks_11
                ShortPeptideLenghtMin = 8,
                ShortPeptideLenghtMax = 13,
                PlotTextLabelSize = 1.6,
                TestMode = FALSE, # if TRUE, only first 100 lines from each file will be loaded; Warning = may mess up correlation plots
                PlotsInteractive = FALSE, #TRUE = interactive in html, FALSE = static
                ResultsOverwrite = TRUE, # FALSE throws error when output files already exist to avoid overwriting
                PlotsSave = FALSE, #Saves all the plots as .png
                CsvSave = FALSE, # TRUE = saves all intermediary csvs, FALSE = saves only essential
                TestStats = FALSE #Performs Anova and T-test to compare conditions TRUE or FALSE)
  )
)

## dda_jy
render(
  input = file.path("0_code", "01_report_main_template.Rmd"),
  output_file = "../01_report_main__hla1_dda_jy.html",
  params = list(Title = "Report: MHC1p evaluation - MEGF_035_K251128_hla1_dda_jy",
                SampleSet = "MEGF_035_K251128",
                DataAnalysisNames = "MF, DGZ",
                WetLabNames = "MF",
                AnnotationFile = "sample_annotation_dda_jy.csv", # Samples Annotation file in /1_documentation
                Subset = "dda_jy", # subset name, is added as prefix to file names and used to creat subfolders for results and figures
                FolderData = "2_data", #for subfolders use "/"
                FolderResults = "3_results",
                FolderFigures = "4_figures",
                Instrument = "tims_tof", #faims_orbi, orbi
                Software = "fragpipe_dda_combined", # options = fragpipe_dda_individual, fragpipe_dda_combined,peaks_xpro, diann; to be added =  peaks_11
                ShortPeptideLenghtMin = 8,
                ShortPeptideLenghtMax = 13,
                PlotTextLabelSize = 1.6,
                TestMode = FALSE, # if TRUE, only first 100 lines from each file will be loaded; Warning = may mess up correlation plots
                PlotsInteractive = FALSE, #TRUE = interactive in html, FALSE = static
                ResultsOverwrite = TRUE, # FALSE throws error when output files already exist to avoid overwriting
                PlotsSave = FALSE, #Saves all the plots as .png
                CsvSave = FALSE, # TRUE = saves all intermediary csvs, FALSE = saves only essential
                TestStats = FALSE #Performs Anova and T-test to compare conditions TRUE or FALSE)
  )
)

## dia_jy
render(
  input = file.path("0_code", "01_report_main_template.Rmd"),
  output_file = "../01_report_main__hla1_dia_jy.html",
  params = list(Title = "Report: MHC1p evaluation - MEGF_035_K251128_hla1_dia_jy",
                SampleSet = "MEGF_035_K251128",
                DataAnalysisNames = "MF, DGZ",
                WetLabNames = "MF",
                AnnotationFile = "sample_annotation_dia_jy.csv", # Samples Annotation file in /1_documentation
                Subset = "dia_jy", # subset name, is added as prefix to file names and used to creat subfolders for results and figures
                FolderData = "2_data", #for subfolders use "/"
                FolderResults = "3_results",
                FolderFigures = "4_figures",
                Instrument = "tims_tof", #faims_orbi, orbi
                Software = "diann", # options = fragpipe_dda_individual, fragpipe_dda_combined,peaks_xpro, diann; to be added =  peaks_11
                ShortPeptideLenghtMin = 8,
                ShortPeptideLenghtMax = 13,
                PlotTextLabelSize = 1.6,
                TestMode = FALSE, # if TRUE, only first 100 lines from each file will be loaded; Warning = may mess up correlation plots
                PlotsInteractive = FALSE, #TRUE = interactive in html, FALSE = static
                ResultsOverwrite = TRUE, # FALSE throws error when output files already exist to avoid overwriting
                PlotsSave = FALSE, #Saves all the plots as .png
                CsvSave = FALSE, # TRUE = saves all intermediary csvs, FALSE = saves only essential
                TestStats = FALSE #Performs Anova and T-test to compare conditions TRUE or FALSE)
  )
)


## dda_plasma
render(
  input = file.path("0_code", "01_report_main_template.Rmd"),
  output_file = "../01_report_main__hla1_dda_plasma.html",
  params = list(Title = "Report: MHC1p evaluation - MEGF_035_K251128_hla1_dda_plasma",
                SampleSet = "MEGF_035_K251128",
                DataAnalysisNames = "MF, DGZ",
                WetLabNames = "MF",
                AnnotationFile = "sample_annotation_dda_plasma.csv", # Samples Annotation file in /1_documentation
                Subset = "dda_plasma", # subset name, is added as prefix to file names and used to creat subfolders for results and figures
                FolderData = "2_data", #for subfolders use "/"
                FolderResults = "3_results",
                FolderFigures = "4_figures",
                Instrument = "tims_tof", #faims_orbi, orbi
                Software = "fragpipe_dda_combined", # options = fragpipe_dda_individual, fragpipe_dda_combined,peaks_xpro, diann; to be added =  peaks_11
                ShortPeptideLenghtMin = 8,
                ShortPeptideLenghtMax = 13,
                PlotTextLabelSize = 1.6,
                TestMode = FALSE, # if TRUE, only first 100 lines from each file will be loaded; Warning = may mess up correlation plots
                PlotsInteractive = FALSE, #TRUE = interactive in html, FALSE = static
                ResultsOverwrite = TRUE, # FALSE throws error when output files already exist to avoid overwriting
                PlotsSave = FALSE, #Saves all the plots as .png
                CsvSave = FALSE, # TRUE = saves all intermediary csvs, FALSE = saves only essential
                TestStats = FALSE #Performs Anova and T-test to compare conditions TRUE or FALSE)
  )
)

## dia_plasma
render(
  input = file.path("0_code", "01_report_main_template.Rmd"),
  output_file = "../01_report_main__hla1_dia_plasma.html",
  params = list(Title = "Report: MHC1p evaluation - MEGF_035_K251128_hla1_dia_plasma",
                SampleSet = "MEGF_035_K251128",
                DataAnalysisNames = "MF, DGZ",
                WetLabNames = "MF",
                AnnotationFile = "sample_annotation_dia_plasma.csv", # Samples Annotation file in /1_documentation
                Subset = "dia_plasma", # subset name, is added as prefix to file names and used to creat subfolders for results and figures
                FolderData = "2_data", #for subfolders use "/"
                FolderResults = "3_results",
                FolderFigures = "4_figures",
                Instrument = "tims_tof", #faims_orbi, orbi
                Software = "diann", # options = fragpipe_dda_individual, fragpipe_dda_combined,peaks_xpro, diann; to be added =  peaks_11
                ShortPeptideLenghtMin = 8,
                ShortPeptideLenghtMax = 13,
                PlotTextLabelSize = 1.6,
                TestMode = FALSE, # if TRUE, only first 100 lines from each file will be loaded; Warning = may mess up correlation plots
                PlotsInteractive = FALSE, #TRUE = interactive in html, FALSE = static
                ResultsOverwrite = TRUE, # FALSE throws error when output files already exist to avoid overwriting
                PlotsSave = FALSE, #Saves all the plots as .png
                CsvSave = FALSE, # TRUE = saves all intermediary csvs, FALSE = saves only essential
                TestStats = FALSE #Performs Anova and T-test to compare conditions TRUE or FALSE)
  )
)


