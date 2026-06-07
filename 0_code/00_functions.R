# Functions and plots

#Load libraries ----

library(ggrepel)
library(janitor)
library(plotly)
library(ggvenn) #devtools::install_github("yanlinlin82/ggvenn")
library(kableExtra)
library(ggupset)
library(viridis)
library(ggside)
library(ggcorrplot)
library(PerformanceAnalytics)
library(ggseqlogo)
library(openxlsx)
library(ggpubr)
library(tidyverse)

# loading files ---- 

## pre-checks ----
check_file_exists <- function(file, overwrite = FALSE){
  # check if a file already exist, throw error if yes and overwrite = TRUE
  # file = file to be checked, full path
  # overwrite = logical, allow overwritting or not
  if(file.exists(file) & overwrite == TRUE){
    warning("The following file already exists and will be overwritten:")
    print(file)
  }
  if(file.exists(file) & overwrite == FALSE){
    stop("The following file already exists. Please rename, replace or remove the conflicting file")
    print(file)
  }
}
# next check applies to several files instead of one by one, makes it easier to get the whole list
check_output_exists <- function(dir, overwrite = FALSE){
  # check if output files already exist, throw error if yes and overwrite = TRUE
  # dir = directory where the results should be stored
  # overwrite = logical, allow overwritting or not
  res_files_found <-
    data.frame(res_file = c(file.path(dir, "seq_by_condition.xlsx"),
                            file.path(dir, "seq_by_workflow.xlsx"),
                            file.path(dir, "seq_overlap_condition.xlsx"),
                            file.path(dir, "seq_overlap_workflow.xlsx"),
                            file.path(dir, "pep_all.csv"),
                            file.path(dir, "summary_peaks.csv"),
                            file.path(dir, "upset_table_pep.csv"),
                            file.path(dir, "upset_table_prot.csv"),
                            file.path(dir, "upset_table_prot.csv"),
                            file.path(dir, "upset_table_unique.csv"),
                            file.path(dir, "pep_overlap.csv"))) %>%
    mutate(found =  file.exists(res_file)) %>%
    filter(found)
  
  if(nrow(res_files_found) >=1 & overwrite == FALSE){
    warning("The following result files were found and they cannot be overwritten. 
            Please rename, replace or remove them before starting the code again")
    
    print(res_files_found)
    stop("Please rename, replace or remove the conflicting result files")
  }
}




## annotation -----


# file_annot = file.path("1_documentation", params$AnnotationFile)
read_annot <- function(file_annot){
  # read, check, and reformat the annotation file
  # file_annot = csv file with annotation table including at least the following columns:  
  # "Condition", "BioReplicate", "TechReplicate", "Sample", ("Sample_fp" or "Sample_peaks")
  annot <- read.csv(file_annot) %>% 
    mutate(across(any_of("Source_file"), ~ gsub(".d|.raw", "", .x))) # if Source_file present, remove extension
  
  # check that it table contains the columns needed
  if(!any(c("Sample_fp", "Sample_peaks") %in%   names(annot))){
    stop("The annotation table must contain Sample_peaks or Sample_fp column, please add it and try again")
  }
  if(!all(c("Condition", "BioReplicate", "TechReplicate", "Sample") %in%   names(annot))){
    stop("The annotation table must contain all the following columns, please add those ones missing and try again.
         Condition, BioReplicate, TechReplicate, Sample")
  }
  # rename Sample_peaks if necessary
  if("Sample_peaks" %in% names(annot)){
    if(any(grepl("-", annot$Sample_peaks))){
      annot <- annot %>%  mutate(Sample_peaks = gsub("-", "_", Sample_peaks))
      warning(" Hyphens ('-') in column Sample_peaks were replaced by underscores '_'
    as this is also done when exporting from PEAKS")
    }
    if(any(grepl(" ", annot$Sample_peaks))){
      annot <- annot %>%  mutate(Sample_peaks = gsub(" ", "_", Sample_peaks))
      warning("Spaces (' ') in column Sample_peaks were replaced by underscores '_'
    as this is also done when exporting from PEAKS")
    }
  }
  #establish factor order with order from annot
  annot <- annot %>%
    mutate(across(where(is.character), function(x) factor(x, levels = unique(x)))) 
  return(annot)  
}


print_annot <- function(input){
  # prints annotation table as a nice html datatable
  input%>% 
    DT::datatable(filter = "top",
                  rownames = FALSE,
                  escape = FALSE, #needed for html link and widgets rendering
                  extensions = c('FixedHeader'),
                  options = list(pageLength = 10,
                                 autoWidth = TRUE,
                                 scientific=TRUE,
                                 fixedHeader = TRUE))
}


## PEAKS ---- 
read_pep_peaks <- function(filedir, folder_peaks_db, instrument ="tims_tof"){
  require(mgsub)
  #read peptide results from peaks folders
  ## instrument = type of MS. One of "tims_tof", "faims_orbi", "orbi"
  pep_renamed <-
    read.csv(file.path(filedir, folder_peaks_db, "peptide.csv")) %>%
    rename_with( ~ gsub(patt = "[.]", rep ="_", .x), everything())  %>%
    rename(Score = X_10lgP) %>%
    rename_with( ~ gsub(patt = "X_", rep ="n_", .x), everything()) %>%
    mutate(Sequence = gsub("\\s*\\([^\\)]+\\)","",as.character(Peptide)), #Get striped sequences
           Charge = as.factor(paste0("+ ",  round(Mass/m_z, 0))),
           Peptide_charge = paste(Peptide, as.numeric(Charge), sep = "_"),
           Nter = as.factor(stringr::str_sub(Peptide, 1,1)),
           Cter = as.factor(stringr::str_sub(Peptide, -1,-1))) %>%
    select(-starts_with("n_Feature_"))
  pep_long <-
    pep_renamed %>%
    rename_with(~mgsub(.x, c("Area_", "ms2r_score_", "ms2r_q_value_pep_"),
                       c("Area#", "ms2r_score_sample#", "ms2r_q_value_pep_sample#"))) %>%
    pivot_longer(cols = contains("#"),
                 names_sep = "#",
                 names_to = c(".value", "Sample_peaks"),
                 values_drop_na = TRUE)
  
  
  #format IMS
  if(instrument == "tims_tof"){
    output <-
      pep_long %>%
      separate(col = X1_k0_Range, into = c("invk0_start", "invk0_end"),
               sep = "-", convert = TRUE, remove =  TRUE) %>%
      mutate(invk0 = ((invk0_end + invk0_start)/ 2))
  }else{
    if(instrument == "faims_orbi"){
      #quick fix to allow faims_orbi compatibility
      output <-
        pep_long %>%
        mutate(X1_k0_Range = paste0(CV, "to", CV)) %>%
        separate(col = X1_k0_Range, into = c("invk0_start", "invk0_end"),
                 sep = "to", convert = TRUE, remove =  TRUE) %>%
        mutate(invk0 = ((invk0_end + invk0_start)/ 2))
      # message("faims_orbi is not fully suported yet. For now, the Compensation Voltage (CV) is renamed as invko (1/k0) in the tables and used as mobility dimension in the plots")
    }else{
      if(instrument == "orbi"){
        #quick fix to allow orbi compatibility
        output <-
          pep_long %>%
          mutate(CV = NA) %>%
          mutate(X1_k0_Range = paste0(CV, "to", CV)) %>%
          separate(col = X1_k0_Range, into = c("invk0_start", "invk0_end"),
                   sep = "to", convert = TRUE, remove =  TRUE) %>%
          mutate(invk0 = ((invk0_end + invk0_start)/ 2))
        # message("orbi is not fully suported yet. For now, the Compensation Voltage (CV) is renamed as invko (1/k0) in the tables and used as mobility dimension in the plots")
      }
    }
    return(output)
  }
}


read_qc_peaks <- function(folder_peaks_qc, sample){
  #read qc files from peaks folders
  output <- read.csv(file.path(folder_peaks_qc, "StatisticsTable.csv"))
  output[,3] <-   as.numeric( sub("%","", output[,3]))
  output <- as.data.frame(t(column_to_rownames(output[,c(2,3)], "X.1")))
  output <-clean_names(output)
  row.names(output) <- NULL
  output <- cbind(Sample = sample, output)
  return(output)
}
read_qc_peaks_single <- function(folder_peaks_qc, annotation){
  #read qc files from single peaks folder, working nicely for single report with several fractions
  annotation <-
    annotation %>%
    select(Condition, BioReplicate, TechReplicate, Sample, Sample_peaks, File_peaks_nb, Fraction_peaks) %>%
    mutate(Fraction_peaks = paste0("F", Fraction_peaks))
  output <-
    read.csv(file.path(folder_peaks_qc, "StatisticsTable.csv")) %>%
    rename_with(~sub("Control..", "", .x)) %>%
    select(-c(X, Total, Average)) %>%
    mutate(across(-X.1, ~as.numeric( sub("%","", .x))) ) %>%
    column_to_rownames("X.1") %>%
    t %>%  as.data.frame() %>%
    clean_names %>%
    rownames_to_column("Fraction_peaks") %>%
    inner_join(annotation, by = "Fraction_peaks") %>%
    relocate(Fraction_peaks, .after = Sample_peaks)
  
  
  return(output)
}




peaks_read_batch <- function(folder, annotation){
  
  #List files
  files_peaks <- get_dirs_index_peaks(folder) 
  #filter to only data in the annotation
  files_peaks <- files_peaks[gsub("QC_", "", files_peaks$path_full) %in% unique(annotation$path_full), ]
  
  output <- lapply(unique(files_peaks[files_peaks$QC == FALSE, "path_full"]),
                   function(x){
                     # x <- unique(files_peaks[files_peaks$QC == FALSE, "path_full"])[4] #for troubleshooting
                     #filter in case there are same sample names across different peaks files
                     annot_x <- annotation %>%
                       filter(path_full == files_peaks[files_peaks$path_full == x, "path_full"]) #projectspecific, complete folder was needed here
                     
                     output_raw <- read_pep_peaks(filedir =getwd(),
                                                  folder_peaks_db = x,
                                                  # instrument = unique(annot_x$Instrument))  #project-specific modifications for compatibility with timsOFF
                                                  instrument = params$Instrument)
                     output <-
                       output_raw %>%
                       rename(Source_File_ID = Source_File) %>%
                       inner_join(., annot_x, by = c("Sample_peaks"))
                     
                     if(nrow(output)  > nrow(output_raw)) stop("Some samples may be duplicated in the annotation file")
                     message("loaded ", x)
                     return(output)
                   })  %>%
    do.call(args = ., what = bind_rows) %>% # clasifier of expected MHC length
    #Get first protein only
    mutate(AccessionFirst = sub("\\:.*", "", Accession)) %>%
    mutate(AccessionFirst = gsub("|", "_", AccessionFirst, fixed = TRUE)) %>%
    separate(AccessionFirst, sep = "_",
             into = c("ProteinFirst", "GeneFirst", "OrganismFirst"),
             fill = "right", extra = "drop") %>%
    arrange(ProteinFirst, m_z) %>%
    mutate(PeptideID =  paste0(ProteinFirst, "_", round(m_z, 1), "_", as.numeric(Charge)),
           Log2Area = ifelse(Area == 0, NA, log(Area,2)),
           Length_range = case_when(Length >= shortpep_range[1] & Length <= shortpep_range[2] ~
                                      paste0(shortpep_range[1], " to ", shortpep_range[2], " AAs"),
                                    Length < shortpep_range[1] |  Length > shortpep_range[2] ~ "others"),
           Length_range = factor(Length_range)) %>%
    select(any_of( #added any_of and condition names in "" for compatibility with DIA 12/12/2025
      c("Condition", "BioReplicate", "TechReplicate", "Sample",
        "Accession", "Peptide",  "Sequence", "Length",
        "Score",
        "Area", "Log2Area",
        "Length_range", "PTM", "AScore", "Charge", "Nter", "Cter",
        "RT", "invk0_start", "invk0", "invk0_end", "Mass", "ppm", "m_z",
        "Sample_ID",  "Sample_peaks", "Source_File", "File_peaks_nb",
        "Source_File_ID", "Precursor_Id", "n_Feature",  "Found_By", "PeptideID", "ProteinFirst", "GeneFirst", "OrganismFirst")
    )) # removed: Fraction, Peptide_charge, path_full, Fraction_peaks
  
  if(any(grepl("#DECOY#", output$Accession))){
    output <- output %>% filter(! grepl("#DECOY#", Accession))
    message("Decoys were included in the raw results. They have been filtered out")
  }
  
  # Check if any non-matched sample
  if(any(is.na(output$Condition))){
    warning("The following samples were not matched with the annotation file and thus will be droped")
    output %>%
      filter(is.na(Condition)) %>%
      select(Condition, Sample, Source_File,  Sample_peaks, File_peaks_nb) %>%  unique %>%
      kable %>%
      kable_paper("hover", full_width = F) %>%
      print()
  }
  return(output)
  
}



## Fragpipe -----
fp_read_psm <- function(folder, samplename, testmode = FALSE){
  # read one fragpipe psm file
  if(testmode == TRUE){
    input <- read_tsv(folder, show_col_types  = FALSE, progress = FALSE, n_max = 100)  
    warning("Test mode ON: only the first 50 lines were loaded")
    
  }else{
    input <- read_tsv(folder, show_col_types  = FALSE, progress = FALSE) 
  }
  input %>% 
  mutate(Sample_fp = samplename) %>% 
    relocate(Sample_fp)
}

#2do: do this more efficiently, currently it reads all the files in the folder, but some may be dropped when annotating 
fp_read_psm_batch <- function(folder, testmode = FALSE){
  # read all fragpipe psm files in the folder and merge them
  ## get index of files in the folder
  
  files_data_all <- list.files(folder, recursive = TRUE)
  
  files_data_psm <-
    file.path(folder, files_data_all[grepl("psm.tsv", files_data_all, fixed = TRUE)])
  ## get sample names
  sample_names <- str_match(files_data_psm, "[/]\\s*(.*?)\\s*[/]psm.tsv")[,2]
  
  psm_raw_list <- 
    lapply(c(1:length(files_data_psm)), function(x){
      fp_read_psm(file.path(files_data_psm[x]), sample_names[x], testmode = testmode)
    }) 
  psm_raw <- do.call(args = psm_raw_list, what = bind_rows) 
  return(psm_raw)
}
#2do: same as for psm, also could be merged into single function

fp_parse_pep_all <- function(input, shortpep_range = c(8, 13)){
  #parse fragpipe psm file into pep_all format for compatibility with downstream code
  # input = output of fp_read_psm_batch
  ## reformat column names, create new ones, then use select to select, rename and reorder columns
  
  if(all(input$Intensity == 0)){
    warning("All Intensity (Area) values were 0. Log2Area will be inputed to 1 to avoid -Inf values")
  } 
  
  input %>% 
    rename_with( ~ gsub(patt = " ", rep ="_", .x), everything()) %>% 
    rename_with( ~ gsub(patt = "/", rep =".", .x, fixed = TRUE), everything()) %>% 
    mutate(
      Retention = Retention/60, #in seconds in Fragpipe but in min in PEAKS
      Modified_Peptide = ifelse(is.na(Modified_Peptide), Peptide, Modified_Peptide), # Modified_Peptide is na if not modified
      PeptideID =  paste0(Protein, "_", round(Calibrated_Observed_M.Z, 1), "_", as.numeric(Charge)),
      OrganismFirst = sub(".*_", "", Entry_Name),
      Log2Area = ifelse(Intensity == 0, 1, log2(Intensity)),
      Charge = as.factor(paste0("+ ",  Charge)),
      Length_range = case_when(Peptide_Length >= shortpep_range[1] & Peptide_Length <= shortpep_range[2] ~
                                 paste0(shortpep_range[1], " to ", shortpep_range[2], " AAs"),
                               Peptide_Length < shortpep_range[1] |  Peptide_Length > shortpep_range[2] ~ "others"),
      Length_range = factor(Length_range),
      Nter = as.factor(stringr::str_sub(Peptide, 1,1)),
      Cter = as.factor(stringr::str_sub(Peptide, -1,-1)), 
      ppm = 1E6*((Calibrated_Observed_M.Z - Calculated_M.Z)/Calculated_M.Z),
      Found_By = "FragPipe",
      Source_file = sub("[.].*", "", Spectrum),
      Source_file = sub("_diatracer", "", Source_file) # faciliate merging when dda+dia worklfow was used
    ) %>%  
    select(Sample_fp,
           Accession = Protein,
           Peptide = Modified_Peptide,
           Sequence = Peptide,
           Length = Peptide_Length,
           Score = Hyperscore,
           Area = Intensity,
           Log2Area,
           Length_range,
           PTM = Assigned_Modifications,
           Charge,
           Nter,
           Cter,
           RT = Retention,
           invk0 = Ion_Mobility,
           Mass = Calibrated_Observed_Mass,
           ppm,
           m_z = Calibrated_Observed_M.Z,
           Source_file,
           Source_File_ID = Spectrum_File,
           Precursor_Id = Spectrum,
           Found_By,
           PeptideID,
           ProteinFirst = Protein_ID,
           GeneFirst = Gene,
           OrganismFirst,
           Nextscore,
           Probability,
           Qvalue,
           Protein_Description,
           Mapped_Genes,
           Mapped_Proteins,
           Is_Decoy,
           Is_Contaminant,
           Is_Unique
    ) 
}

fp_annotate <- function(input, annotation, mode = "individual_files"){
  #Assign the Fragpipe results to groups. Samples are ordered in factors in function of the annotation table
  # input = output of fp_parse_pep_all  # annotation = annotation table with at least the following columns:  
  # "Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_fp"
  # Sample_fp is used to match between the table and Fragpipe results (subfolder names)
  # mode =
  ## "individual_files" if one folder per file, Sample_fp is used for annotation;
  ## "combined_file" if using combined psm, Sample_fp and Source_file are used for annotation
  
  ## check if annotation table has all the information needed
  minimal_columns <- c("Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_fp")
  
  if(!all(minimal_columns %in% names(annotation))){
    stop(paste0("The following columns are missing from the annotation table, please add them:\n",
                paste0(minimal_columns[!minimal_columns %in% names(annotation)],  collapse = ", ")))
  }
  ## throw a warning if some samples will be dropped
  ### need to use both Sample_fp and Source_file in case of multiple results per sample
  input_samples <- 
    input %>%
    select(Sample_fp, Source_file) %>%
    unique() %>%
    arrange(Sample_fp, Source_file) %>% 
    unite(col = "Sample", Sample_fp, Source_file, sep = ",", remove = TRUE ) %>% 
    pull(Sample)
  
  annotation_samples <-
    annotation %>%
    select(Sample_fp, Source_file) %>%
    unique() %>%
    arrange(Sample_fp, Source_file) %>% 
    unite(col = "Sample", Sample_fp, Source_file, sep = ",", remove = TRUE ) %>% 
    pull(Sample)
  if(all(input_samples %in% annotation_samples) & all(annotation_samples %in% input_samples)){
    message("All samples were correctly matched between the input results and the annotation table")
  }
  
  if(!all(input_samples %in% annotation_samples)){
    warning(paste0("The following samples from the input results were not found in the annotation table and will be dropped:\n",
                   paste0(input_samples[!input_samples %in% annotation_samples],  collapse = "; ")))
  }
  if(!all(annotation_samples %in% input_samples)){
    warning(paste0("The following samples (Sample_fp,Source_file) from the annotation table were not found in the input results and will be dropped:\n",
                   paste0(annotation_samples[!annotation_samples %in% input_samples],  collapse = ", ")))
  }
  if(!all(input_samples %in% annotation_samples)){
    warning(paste0("The following samples (Sample_fp,Source_file) from the input results were not found in the annotation table  and will be dropped:\n",
                   paste0(annotation_samples[!annotation_samples %in% input_samples],  collapse = ", ")))
  }
  ## merge
  if(mode == "individual_files") {
    output <- 
      inner_join(annotation, input, by = c("Sample_fp")) %>% 
      relocate(Sample_ID, .after = "Is_Unique")
  }
  if(mode == "combined_file"){
    ## check if annotation table contains Source_file
    if(!all(c("Source_file") %in% names(annotation))){
      stop("combined_file mode was activated, but the Source_file column is missing from the annotation table, please add it")
    }
    output <- input %>% 
      # mutate(Source_file = sub("[.].*", "", Precursor_Id))  %>%
      inner_join(annotation, ., by = c("Source_file", "Sample_fp")) %>% 
      relocate(Sample_ID, .after = "Is_Unique") %>% 
      droplevels() # necessary to avoid dragging empty factors that create errors
  }
  return(output)
}

diann_read_tsv_batch <- function(folder, testmode = FALSE){
  # read all fragpipe psm files in the folder and merge them
  ## get index of files in the folder
  
  files_data_all <- list.files(folder, recursive = TRUE)
  
  files_data_psm <-
    file.path(folder, files_data_all[grepl("report.tsv", files_data_all, fixed = TRUE)])
  ## get sample names
  sample_names <- str_match(files_data_psm, "[/]\\s*(.*?)\\s*[/]report.tsv")[,2]
  
  psm_raw_list <- 
    lapply(c(1:length(files_data_psm)), function(x){
      fp_read_psm(file.path(files_data_psm[x]), sample_names[x], testmode = testmode)
    }) 
  psm_raw <- do.call(args = psm_raw_list, what = bind_rows) 
  return(psm_raw)
}

diann_parse_pep_all <- function(input, shortpep_range = c(8, 13)){
  #parse diann report.tsv file into pep_all format for compatibility with downstream code
  # input = output of diann_read_tsv_batch
  ## reformat column names, create new ones, then use select to select, rename and reorder columns
  # mass and ppm not calculated
  input  %>% 
    rename_with( ~ gsub(patt = " ", rep =".", .x), everything()) %>%
    # rename_with( ~ gsub(patt = "/", rep =".", .x, fixed = TRUE), everything()) %>%
    mutate(
      PeptideID =  paste0(All.Mapped.Proteins, "_", round(Precursor.Mz, 1), "_", as.numeric(Precursor.Charge)),
      OrganismFirst = gsub(".*_(.+).*", "\\1", All.Mapped.Proteins),
      Log2Area = ifelse(Ms1.Area == 0, 1, log2(Ms1.Area)),
      Charge = as.factor(paste0("+ ",  Precursor.Charge)),
      PTM = apply(str_extract_all(Modified.Sequence, "\\([^()]+\\)", simplify = TRUE),
                  1, 
                  function(row) paste(row[nzchar(row)], collapse = ", ")),
      Length = nchar(Stripped.Sequence),
      Length_range = case_when(Length >= shortpep_range[1] & Length <= shortpep_range[2] ~
                                 paste0(shortpep_range[1], " to ", shortpep_range[2], " AAs"),
                               Length < shortpep_range[1] |  Length > shortpep_range[2] ~ "others"),
      Length_range = factor(Length_range),
      Nter = as.factor(stringr::str_sub(Stripped.Sequence, 1,1)),
      Cter = as.factor(stringr::str_sub(Stripped.Sequence, -1,-1)), 
      Mass = ((Precursor.Mz - 1.007276)*Precursor.Charge),
      ppm = 0, # DIA-NN does not give a calculated mz
      # ppm = 1E6*((Calibrated_Observed_M.Z - Calculated_M.Z)/Calculated_M.Z),
      Source_file = gsub(".*\\\\(.+)[.].*", "\\1", File.Name),
      Found_By = "DIA-NN"
    ) %>%  
    select(Sample_fp,
           Accession = All.Mapped.Proteins,
           Peptide = Modified.Sequence,
           Sequence = Stripped.Sequence,
           Length,
           Score = Q.Value,
           Area = Ms1.Area,
           Log2Area,
           Length_range,
           PTM,
           Charge,
           Nter,
           Cter,
           RT = RT,
           invk0 = IM,
           Mass,
           ppm,
           m_z = Precursor.Mz,
           Sample_fp,
           Source_file,
           Source_File_ID = Run,
           Precursor_Id = Precursor.Id,
           Found_By,
           PeptideID,
           ProteinFirst = Protein.Group,
           GeneFirst = Genes,
           OrganismFirst,
           Area_MS2 = Precursor.Normalised,
           Protein.Ids,
           Protein.Names,
           PG.Quantity,
           PG.Normalised,
           PG.MaxLFQ,
           Genes.Quantity,
           Genes.Normalised,
           Genes.MaxLFQ,
           Genes.MaxLFQ.Unique,
           PEP,
           Global.Q.Value,
           Protein.Q.Value,
           PG.Q.Value,
           Global.PG.Q.Value,
           GG.Q.Value,
           Translated.Q.Value,
           Proteotypic,
           Precursor.Quantity,
           Precursor.Translated,
           Translated.Quality,
           Ms1.Translated,
           Quantity.Quality,
           iRT,
           RT.Start,
           RT.Stop,
           Predicted.RT,
           Predicted.iRT,
           Lib.Q.Value,
           Lib.PG.Q.Value,
           Ms1.Profile.Corr,
           Evidence,
           Spectrum.Similarity,
           Averagine,
           Mass.Evidence,
           CScore,
           Decoy.Evidence,
           Decoy.CScore,
           Fragment.Quant.Raw,
           Fragment.Quant.Corrected,
           Fragment.Correlations,
           MS2.Scan,
           Fragment.Info,
           Lib.Index,
           iIM,
           Predicted.IM,
           Predicted.iIM,
           All.Mapped.Genes
    ) 
}


diann_annotate <- function(input, annotation){
  #Assign the Fragpipe results to groups. Samples are ordered in factors in function of the annotation table
  # input = output of fp_parse_pep_all  # annotation = annotation table with at least the following columns:  
  # "Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_fp"
  # Sample_fp is used to match between the table and Fragpipe results (subfolder names)
  # mode =
  ## "individual_files" if one folder per file, Sample_fp is used for annotation;
  ## "combined_file" if using combined psm, Sample_fp and Source_file are used for annotation
  
  ## check if annotation table has all the information needed
  minimal_columns <- c("Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_fp")
  
  if(!all(minimal_columns %in% names(annotation))){
    stop(paste0("The following columns are missing from the annotation table, please add them:\n",
                paste0(minimal_columns[!minimal_columns %in% names(annotation)],  collapse = ", ")))
  }
  ## throw a warning if some samples will be dropped
  ### need to use both Sample_fp and Source_file in case of multiple results per sample
  input_samples <- 
    input %>%
    select(Sample_fp, Source_file) %>%
    unique() %>%
    arrange(Sample_fp, Source_file) %>% 
    unite(col = "Sample", Sample_fp, Source_file, sep = ",", remove = TRUE ) %>% 
    pull(Sample)
  
  annotation_samples <-
    annotation %>%
    select(Sample_fp, Source_file) %>%
    unique() %>%
    arrange(Sample_fp, Source_file) %>% 
    unite(col = "Sample", Sample_fp, Source_file, sep = ",", remove = TRUE ) %>% 
    pull(Sample)
  
  if(all(input_samples %in% annotation_samples) & all(annotation_samples %in% input_samples)){
    message("All samples were correctly matched between the input results and the annotation table")
  }
  
  if(!all(input_samples %in% annotation_samples)){
    warning(paste0("The following samples from the input results were not found in the annotation table and will be dropped:\n",
                   paste0(input_samples[!input_samples %in% annotation_samples],  collapse = "; ")))
  }
  if(!all(annotation_samples %in% input_samples)){
    warning(paste0("The following samples (Sample_fp,Source_file) from the annotation table were not found in the input results and will be dropped:\n",
                   paste0(annotation_samples[!annotation_samples %in% input_samples],  collapse = ", ")))
  }
  if(!all(input_samples %in% annotation_samples)){
    warning(paste0("The following samples (Sample_fp,Source_file) from the input results were not found in the annotation table  and will be dropped:\n",
                   paste0(annotation_samples[!annotation_samples %in% input_samples],  collapse = ", ")))
  }
  ## merge
  ## check if annotation table contains Source_file
  if(!all(c("Source_file") %in% names(annotation))){
    stop("combined_file mode was activated, but the Source_file column is missing from the annotation table, please add it")
  }
  output <- input %>% 
    # mutate(Source_file = sub("[.].*", "", Precursor_Id))  %>%
    inner_join(annotation, ., by = c("Source_file", "Sample_fp")) %>% 
    relocate(Sample_ID, .after = "All.Mapped.Genes") %>% 
    droplevels() # necessary to avoid dragging empty factors that create errors
  return(output)
}

# processing -----
count_ids <- function(input){
  input  %>%
    summarise(n_Peptides = n_distinct(Peptide, na.rm = TRUE),
              n_Sequences = n_distinct(Sequence, na.rm = TRUE),
              n_Proteins = n_distinct(Accession, na.rm = TRUE),
              .groups = "drop")
  
}

## Plots

theme_rawr <-
  theme_pubr(base_size = 8, legend  = "top")+
  theme(strip.background = element_blank(),
        strip.text = element_text(size=8),
        axis.text.x = element_text(size = 8),
        legend.key.size = unit(0.7, "lines"),
        plot.title=element_text(face="bold", size =8))

plot_peplength <- function(input, title, ylimits=NULL, xlimits = NULL){
  #Peptide length histogram showing counts
  max_count <- input %>%  group_by(Length) %>% count() %>%  max()
  max_x <-  max(input$Length)
  if(is.null(ylimits)){
    ylimits <- c(0,ceiling(max_count/1000)*1000)
  }else{
    ylimits <- ylimits
  }
  if(is.null(xlimits)){
    xlimits <- c(0,ceiling(max_x/10)*10)
  }else{
    xlimits <- xlimits
  }
  
  p_length_bp <-
    input %>%
    ggplot(aes(x = Length)) +
    geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    stat_boxplot(geom ='errorbar',width=0.5) +
    theme_pubr() +
    clean_theme() +
    theme(strip.background = element_blank(), strip.text = element_text(face = "bold", size = 2)) +
    scale_x_continuous(limits = xlimits, breaks = seq(0,xlimits[2], by = 1))
  p_length_hist <-
    input %>%
    ggplot(aes(x = Length)) +
    geom_histogram(fill = "#39568CFF", binwidth = 1) +
    # geom_vline(xintercept= 7.5, linetype="dotted", alpha = 0.8, color = "#1F968BFF")+
    # geom_vline(xintercept= 13.5, linetype="dotted", alpha = 0.8, color = "#1F968BFF")+
    # annotate("text", color = "#1F968BFF", size = 2,
    #          x = 7.8, hjust = 0, y = max_count*1.2,
    #          label = "8 - 13") +
    scale_y_continuous(limits = ylimits, breaks = seq(0,ylimits[2], by = 1000))+
    scale_x_continuous(limits = xlimits, breaks = seq(0,xlimits[2], by = 3))+
    ylab("Peptide count") +
    xlab("Peptide length")+
    theme_rawr 
  ggarrange(p_length_bp, p_length_hist, nrow = 2,heights = c(0.15, 0.85), align = "v") %>%
    annotate_figure(top = text_grob(title, face="bold", size=8))
}

plot_peplength_dens <- function(input, title, ylimits=NULL, xlimits = NULL){
  #Peptide length histogram showing density
  max_count <- input %>%  group_by(Length) %>% count() %>%  max()
  max_x <-  max(input$Length)
  if(is.null(ylimits)){
    ylimits <- c(0,ceiling(max_count/1000)*1000)
  }else{
    ylimits <- ylimits
  }
  if(is.null(xlimits)){
    xlimits <- c(0,ceiling(max_x/10)*10)
  }else{
    xlimits <- xlimits
  }
  
  p_length_bp <-
    input %>%
    ggplot(aes(x = Length)) +
    geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    stat_boxplot(geom ='errorbar',width=0.5) +
    theme_pubr() +
    clean_theme() +
    theme(strip.background = element_blank(), strip.text = element_text(face = "bold", size = 2)) +
    scale_x_continuous(limits = xlimits, breaks = seq(0,xlimits[2], by = 1))
  p_length_hist <-
    input %>%
    ggplot(aes(x = Length, y = ..density..)) +
    geom_histogram(fill = "#39568CFF", binwidth = 1) +
    scale_x_continuous(limits = xlimits, breaks = seq(0,xlimits[2], by = 3))+
    xlab("Peptide length")+
    theme_rawr 
  ggarrange(p_length_bp, p_length_hist, nrow = 2,heights = c(0.15, 0.85), align = "v") %>%
    annotate_figure(top = text_grob(title, face="bold", size=8))
}


plot_pepmass <- function(input, title, xlimits=NULL){
  ## Finding apex based on http://ianmadd.github.io/pages/PeakDensityDistribution.html
  max_dens_x <- density(input$Mass)$x[which.max(density(input$Mass)$y)] #Find distribution apex
  max_dens_y <- density(input$Mass)$y[which.max(density(input$Mass)$y)] #Find distribution apex
  
  p_mass_bp <-
    input %>%
    ggplot(aes(x = Mass)) +
    geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    stat_boxplot(geom ='errorbar',width=0.5) +
    theme_pubr() +
    clean_theme() +
    theme(strip.background = element_blank(), strip.text = element_text(face = "bold"))
  
  p_mass_hist <-
    input %>%
    ggplot(aes(x = Mass)) +
    geom_histogram(aes(y = ..density..), fill = "#39568CFF", color = "white",
                   binwidth = 50, size = 0.1) +
    geom_density(color = "black", size=0.5, alpha = 0.5) +
    annotate("text", color = "black", size = 3,
             x = max_dens_x*1.1, hjust = 0, y = max_dens_y*1.1,
             label = paste0("Apex = ", round(max_dens_x, 1))) +
    ylab("Density") +
    xlab("Peptide Mass (Da)")+
    theme_rawr
  if(!is.null(xlimits)){
    p_mass_bp <- p_mass_bp + scale_x_continuous(limits = xlimits)
    p_mass_hist <- p_mass_hist + scale_x_continuous(limits = xlimits)
  }
  
  
  ggarrange(p_mass_bp, p_mass_hist, nrow = 2,heights = c(0.15, 0.85), align = "v") %>%
    annotate_figure(top = text_grob(title, face="bold", size=10))
}



plot_pepmz<- function(input, title, xlimits=NULL){
  ## Finding apex based on http://ianmadd.github.io/pages/PeakDensityDistribution.html
  max_dens_x <- density(input$m_z)$x[which.max(density(input$m_z)$y)] #Find distribution apex
  max_dens_y <- density(input$m_z)$y[which.max(density(input$m_z)$y)] #Find distribution apex
  
  
  p_mass_bp <-
    input %>%
    ggplot(aes(x = m_z)) +
    geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    stat_boxplot(geom ='errorbar',width=0.5) +
    theme_pubr() +
    clean_theme() +
    theme(strip.background = element_blank(), strip.text = element_text(face = "bold"))
  p_mass_hist <-
    input %>%
    ggplot(aes(x = m_z)) +
    geom_histogram(aes(y = ..density..), fill = "#39568CFF", color = "white",
                   binwidth = 50, size = 0.1) +
    geom_density(color = "black", size=0.5, alpha = 0.5) +
    annotate("text", color = "black", size = 3,
             x = max_dens_x*1.1, hjust = 0.5, y = max_dens_y*1.1,
             label = paste0("Apex = ", round(max_dens_x, 1))) +
    ylab("Density") +
    xlab("Peptide m/z")+
    theme_rawr
  
  if(!is.null(xlimits)){
    p_mass_bp <- p_mass_bp + scale_x_continuous(limits = xlimits)
    p_mass_hist <- p_mass_hist + scale_x_continuous(limits = xlimits)
  }
  
  ggarrange(p_mass_bp, p_mass_hist, nrow = 2,heights = c(0.15, 0.85), align = "v") %>%
    annotate_figure(top = text_grob(title, face="bold", size=10))
}



plot_venn4 <-  function(input, variable, group){
  require(ggvenn)
  output <- input %>%
    arrange(variable) %>%
    with(., split(get(variable), get(group)))  %>%
    ggvenn(text_size = 3,
           set_name_size= 3,
           fill_alpha = 0.5,
           fill_color = c("#440154FF", "#39568CFF", "#1F968BFF", "#FDE725FF"),
           label_sep = "_") +
    # theme(plot.margin = margin(-0.5, -2, -0.5, -2, "cm"))
    theme(plot.margin = margin(0, 0, 0, 0, "cm"),
          # plot.background = element_rect(fill = "white"),
          plot.title = element_text(size=10, face = "bold"))
  return(output)
}

ggsave_rawr <-function(input, file, width = 8, height = 10) {
  if(exists(deparse(substitute(input))) == TRUE){
    ggsave(file.path("4_figures", paste0(file, ".png")) , input, device =  "png",
           scale = 1, width = width, height = height, units = "cm")
  }else{
    warning(paste0(file, ".png was not saved because the plot was not generated"))
  }
}

plot_upset <- function(df, vars, n_intersections = 10, Compare = "Condition"){
  # get an upset plot of the number of different vars
  ## prepare data
  df[, "Compare"] <- df[, Compare]
  df_distinct <- df %>%
    distinct(Compare, {{ vars }}, .keep_all= FALSE)
  df_distinct_total <-  df_distinct %>% pull({{ vars }}) %>%  n_distinct()
  ## plot
  df_distinct %>%
    group_by({{ vars }}) %>%
    summarize(Compare = list(as.character(Compare)), .groups = "drop") %>%
    ggplot(aes(x=Compare)) +
    geom_bar(fill ="#39568CFF") +
    geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.2, size = 2) +
    scale_x_upset(n_intersections = n_intersections) +
    theme_bw(base_size = 8)+
    theme(plot.margin = unit(c(0.5,0.5,0.5,3), "cm")) +
    theme_combmatrix(
      combmatrix.panel.point.color.fill = "#39568CFF",
      combmatrix.panel.line.size = 0,
      combmatrix.label.make_space = FALSE) +
    labs(caption = paste0("Total unique = ", df_distinct_total, "    Max. intersections shown = ", n_intersections))
}

ggseqlogo_bylength <- function(input, seq_length, by,  ...){
  # Get motifs of peptide sequences depending on a certain length
  ## Get sequences and groups
  input_filtered <- input %>%
    filter(Length == seq_length) %>%
    select(all_of(by), Sequence) %>%
    unique %>% droplevels
  ## Check if some groups were droped due to not having sequences
  by_input<- input %>%  pull(by) %>%  unique
  by_input_filtered <- input_filtered %>%  pull(by) %>%  unique
  if(length(by_input) != length(by_input_filtered)){
    print(paste0("The following groups were droped because no Sequence with Length = ", seq_length , " was found: ", paste(by_input[!by_input %in% by_input_filtered]), "\n", collapse = ", "))
    
  }
  ## Get in list format
  input_filtered_list <- lapply(split(input_filtered[-1], input_filtered[, by]), function(x) x[x != ""])
  ## plot
  input_filtered_list %>%
    ggseqlogo(scales = "free", ...) +
    theme(plot.background = element_rect(fill = "white"))
}


list_sequences <- function(input, by){
  input_min <- input %>%  select(all_of(by), Sequence) %>%
    unique %>%  droplevels #we need only the unique sequences
  lapply(split(input_min[-1], input_min[, by]), function(x) x[x != ""])
}

plot_heatmap <- function(mat, annotation, level, group, n_clust = 5, width = 24, height = 24, units = "cm", res = 100, keysize = 0.9, file, ...){
  
  # Simple heatmap using heatmap.2
  # mat = matrix of numeric functions
  #https://www.datanovia.com/en/lessons/heatmap-in-r-static-and-interactive-visualization/#enhanced-heat-maps-heatmap.2
  require(gplots)
  require(RColorBrewer)
  # library(pals)
  
  
  
  bins_palette <- ifelse(diff(range(mat)) > 100, 100, diff(range(mat)))
  
  palette_hm <- colorRampPalette(brewer.pal(11, "RdBu"))(bins_palette)
  
  # ColSideColors
  
  # set the custom distance and clustering functions
  hclustfunc <- function(x) hclust(x, method="complete")
  distfunc <- function(x) dist(x, method="euclidean")
  
  # perform clustering on rows and columns
  cl.row <- hclustfunc(distfunc(mat))
  cl.col <- hclustfunc(distfunc(t(mat)))
  
  # extract cluster assignments; i.e. k=8 (rows) k=5 (columns)
  gr.row <- cutree(cl.row, n_clust)
  # gr.col <- cutree(cl.col, 5)
  ## Use Condition to color the columns
  gr.col <-
    annotation %>%
    select(all_of(c(level, group))) %>% distinct() %>%
    mutate(Condition = as.integer(as.factor(get(group)))) %>%
    column_to_rownames(level) %>%
    t
  # get colors
  # col1 <- brewer.pal(n_clust, "Set1")
  # col2 <- brewer.pal(max(t(gr.col)), "Set2")
  col1 <- magma(n_clust)
  col2 <- viridis(max(t(gr.col)))
  
  png(filename  = file, width = width, height = height, units = units, res = res)
  par(oma=c(4,2,2,2))
  # require(gplots)
  heatmap.2(mat, hclustfun=hclustfunc, distfun=distfunc,
            col =  palette_hm,  trace = "none",
            RowSideColors=col1[gr.row], ColSideColors=col2[gr.col], keysize = keysize, ...)
  dev.off()
  message(paste0("Heatmap saved in ", file.path("4_figures", "hm_pep_all_log2area_br_nonscaled.png")))
  
}


plot_pca <- function(input, annotation,
                     width = 16, height = 9,
                     device = "png",  shape, color){
  require(viridisLite)
  input_scores <-
    input %>%
    pcaMethods::scores() %>%
    as.data.frame() %>%
    rownames_to_column(var = "Sample") %>%
    left_join(., annotation, by = "Sample") %>%
    separate(col = Condition, into = c("VEGF", "LPS"),  sep = "_", remove = FALSE) %>%
    mutate(across(c("VEGF", "LPS"), as.factor))
  #Format names
  p_labels <-
    data.frame(R2 = c(R2cum(input)[1],diff(R2cum(input)))) %>%
    mutate(PC = paste0("PC",row_number()),
           label = sprintf("%s (%.2f%%)", PC, R2*100)) %>%
    select(-R2)
  
  
  p <-
    ggplot(input_scores, aes_string(x ="PC1", y = "PC2", shape = shape, color = color)) +
    geom_point()  +
    xlab(p_labels[p_labels$PC == "PC1", "label"]) +
    ylab(p_labels[p_labels$PC == "PC2", "label"]) +
    labs(shape = shape, color = color) +
    theme_classic(base_size = 8)  +
    scale_color_viridis_d()
  return(p)
}


# Archived functions, integrated into

# library(deltaProtR) #deltaProtR is a package under development by DavidGZ https://github.com/DavidGZ1/deltaProtPeaks or https://github.com/DavidGZ1/deltaProtR


#' Summarise all numeric variables by group
#'
#' Group the dataframe then calculate for each numeric variable the mean, sd, and cv
#'
#' @param df input data frame
#' @param group groups submitted to group_by
#' @param digits_signif number of digits of significance to be reported
#' @param sep character used to separate the column and function in the resulting column names
#' @return ungrouped data frame with the mean, sd, cv, by group columns
#' @keywords summary, mean, sd, cv
#' @export
#' @examples
#' summarise_numeric_by(iris, Species)
#
# summarise_numeric_by <- function(data, group, digits_signif = 8, sep = "."){
#   require(dplyr)
#
#   # helper function for coefficient of variation
#   cv <- function(x, na.rm = TRUE){
#     res <- mean(x, na.rm = na.rm)/sd(x, na.rm = na.rm)
#     res <- ifelse(is.infinite(res), 0, res)
#   }
#   data %>%
#     group_by({{ group }}) %>%
#     summarise(across(where(is.numeric), list(mean = mean, sd = sd, cv = cv), na.rm = TRUE, .names = paste0("{col}",sep, "{fn}")),
#               .groups = "drop") %>%
#     mutate(across(where(is.numeric), signif, digits = digits_signif))
#
# }
# get_peaks_files_index <- function(directory, recursive = FALSE){
#   # compile the information about PEAKS folders in folder
#   data.frame(path_full = list.dirs(directory, recursive =  recursive))  %>%
#     mutate(QC = ifelse(grepl("_QC_", path_full), TRUE, FALSE),
#            Mode = ifelse(grepl("LIB", path_full), "DIA", "DDA"),
#            Type = case_when(grepl("PTM_", path_full) ~ "PEAKS PTM",
#                             grepl("SPIDER_", path_full) ~ "SPIDER",
#                             TRUE ~ "PEAKS"),
#            Type = ifelse(QC == TRUE, paste0("QC_", Type), Type),
#            Folder = gsub(paste0(directory,"/"), "", path_full),
#            Project = str_extract(Folder, patt =  paste0(".+?(?=_",Type, ")")),
#            File_peaks_nb = str_replace(Folder, patt = paste0(Project, "_", Type, "_"), rep = ""))
# }


# imported from functions_thunder

count_ids_condition_bylengthrange <-function(input){
  # get IDs count by LengthRange and Condition
  # count_ids from thunder, works differently to the other one above
  count_ids <- function(input, ..., total = FALSE){
    # count distinct entries for Modified_Peptides.Modified, Peptides.Modified and Proteins
    # input = a dataframe of PEAKS formated peptide result
    # total = logical, if TRUE a row with totals is included
    # ... = variable(s) to be used for grouping
    counts_ids <- input  %>%
      group_by(...) %>%
      summarise(n_Peptides.Modified = n_distinct(Peptide, na.rm = TRUE),
                n_Peptides = n_distinct(Sequence, na.rm = TRUE),
                n_Proteins = n_distinct(Accession, na.rm = TRUE),
                .groups = "drop")
    
    if(total == TRUE){
      count_total <-
        input %>%
        mutate(across(c(...), ~sub(.x, pattern = ".*", replacement = "Total"))) %>%
        group_by(...) %>%
        summarise(n_Peptides.Modified = n_distinct(Peptide, na.rm = TRUE),
                  n_Peptides = n_distinct(Sequence, na.rm = TRUE),
                  n_Proteins = n_distinct(Accession, na.rm = TRUE),
                  .groups = "drop")
      
      counts_ids <-  rbind(counts_ids, count_total)
    }
    return(counts_ids)
  }
  
  
  # get factors in dynamic way (added 26/09/2023) #this messed up with order for plots
  if(is.factor(input$Length_range)){
    levels_length <- levels(input$Length_range)
  }else{
    levels_length <- unique(input$Length_range)
  }
  
  ## Condition total
  counts_by_length_total <-
    bind_rows(count_ids(input, Condition) %>%
                mutate(Length_range =  "All peptides"),
              count_ids(input, Condition, Length_range)) %>%
    #arrange factors in a logical way
    mutate(Length_range = factor(Length_range,
                                 levels = c("All peptides", rev(levels_length))))
  
  ## Proportion in absolute numbers
  prop_by_length_total <-
    counts_by_length_total %>%
    pivot_longer(cols = starts_with("n_"), names_to = "Level", values_to = "Count", names_prefix = "n_") %>%
    group_by(Condition, Level) %>%
    mutate(Proportion = round(Count/Count[Length_range == "All peptides"], 2),
           Percentage = paste0(Proportion*100, "%")) %>%
    # arrange(Condition, Level, desc(Proportion)) %>%
    arrange(Condition, Level, desc(Length_range)) %>% #this may messup with order for plots
    mutate(CumProportion = cumsum(Proportion), #this may messup with order for plots
           # mutate(CumProportion = cumsum(Proportion)-1,
           CumCount = cumsum(Count),
           CumCount = ifelse(Length_range != "All peptides",
                             CumCount -  Count[Length_range == "All peptides"],
                             Count)) %>%
    ungroup()
  
  return(prop_by_length_total)
}



plot_prop_length_condition <- function(input, level2plot = "Peptides", size = params$PlotTextLabelSize){
  # plot the proportion of peptides in function of Length_range classes
  #Input = output of count_ids_condition_bylengthrange
  input %>%
    filter(Length_range !=  "All peptides",
           Level == level2plot) %>%
    droplevels %>%
    # mutate(PositionProp = ifelse(Length_range == "others", CumCount*0.95, CumCount*0.8)) %>%
    
    # mutate(PositionProp = ifelse(Length_range == "others", 0.98, 0.4)) %>%
    ggplot(aes(x = Condition, y= Proportion, group = Length_range)) +
    geom_bar(stat = "identity",
             aes(fill = Length_range),
             position  = position_stack()) +
    geom_text(aes(label = Percentage, y =  CumProportion - 0.015), size = params$PlotTextLabelSize) +
    theme_rawr +
    scale_y_continuous(breaks = seq(0, 1, 0.25), labels = c("0", "", "50", "", "100"), limits = c(0, 1.02)) +
    # scale_y_continuous(labels = scales::percent, limits = c(0, 1.01), breaks = seq(0, 1, 0.25)) +
    labs(fill = "Length") +
    ylab("% Peptides") +
    scale_fill_viridis_d(end = 1,  alpha = 0.5) +
    theme(legend.position = "right")  +
    guides(fill = guide_legend(override.aes = list(size = 0.3)))
}


get_charge_group <- function(input){
  input %>%
    mutate(Charge = as.numeric(Charge)) %>%
    # unique()
    mutate(Charge_group = factor(case_when(Charge < 3 ~ paste0("+ ", Charge),
                                           TRUE ~ "\u2265 +3"),
                                 c("+ 1", "+ 2", "\u2265 +3")))
}
get_proportion_charge <- function(df){
  df %>%
    pivot_longer(cols = starts_with("n_"), names_to = "Level", values_to = "Count", names_prefix = "n_") %>%
    group_by(Condition, Level) %>%
    mutate(Proportion = round(Count/Count[Charge_group == "Total"], 3),
           Percentage = paste0(Proportion*100, "%")) %>%
    arrange( Condition, Level, desc(Charge_group)) %>%
    mutate(CumProportion = cumsum(Proportion)-1) %>%
    ungroup()
}

plot_charge_proportions <- function(input, variable){
  # input = output from get_proportion_charge()
  input %>%
    filter(Charge_group !=  "Total",
           Level == "Peptides") %>%
    droplevels %>%
    arrange(Charge_group)  %>%
    mutate(PositionProp = case_when(Charge_group == "+ 1" ~ CumProportion - 0.02,
                                    Charge_group == "+ 2" ~ CumProportion*0.9,
                                    TRUE ~ CumProportion*0.9)) %>%
    ggplot(aes(x = {{ variable }}, y = Proportion, fill = Charge_group, group = Charge_group)) +
    geom_bar(stat = "identity", alpha = 0.5) +
    geom_text(aes(label = Percentage, y = Proportion),
              size = params$PlotTextLabelSize, position = position_stack(vjust = 0.8)) +
    
    # scale_y_continuous(breaks = seq(0, 1, 0.25), labels = c("0", "", "50", "", "100"), limits = c(0, 1.02)) + # removed since for fragpipe total may be 100%, due to multiple charges assigned
    scale_y_continuous(breaks = seq(0, 2, 0.25), labels = c("0", "", "50", "", "100", "", "150", "", "200")) + # removed since for fragpipe total may be 100%, due to multiple charges assigned
    # scale_y_continuous(labels = scales::percent, limits = c(0, 1.01), breaks = seq(0, 1, 0.25)) +
    theme_rawr +
    scale_fill_viridis_d(end = 0.7, name = "Charge") +
    scale_color_viridis_d(end = 0.7, name = "Charge") +
    theme(legend.position = "right")   +
    guides(fill = guide_legend(override.aes = list(size = 0.3))) +
    ylab("% Peptides")
}
count_ids_by <-function(input, ...){
  # get wide table with peptide identifications by ...
  input %>% 
    group_by(..., Accession, ProteinFirst, GeneFirst, Length, Peptide, Sequence) %>% 
    summarise(n_Samples = n_distinct(Sample),
              .groups = "drop") %>% 
    pivot_wider(id_cols = c(Accession, ProteinFirst, GeneFirst, Length, Peptide, Sequence),
                names_from = Condition, values_from = c(n_Samples),
                names_prefix = "n_Samples.", names_sep = ".", values_fill = 0) %>% 
    arrange(Accession, ProteinFirst, GeneFirst, Length, Peptide, Sequence)
}

summarise_area <- function(input, by){
  # summarize area by a variable, input = pep_
  input %>%
    group_by(Accession, Peptide,  Charge, {{by}}) %>%
    summarise(Count = sum(!is.na(Area)), 
              Area_mean = mean(Area, na.rm = TRUE),
              Area_sd = sd(Area, na.rm = TRUE),
              Area_CV = Area_sd/Area_mean,
              Area_CV_perc = Area_CV * 100,
              .groups = "drop")  %>% 
    ungroup()
}


plot_violin_areacv <- function(input, by){
  # plot violin and boxplots of area_CV
  # input = outuput of summarise_area
  
  ## get ylim
  cv_ylim <- ceiling(max(input$Area_CV, na.rm=TRUE)*12)/10
  ## plot
  input %>% 
    # filter(Count >= 2, !is.na(Area_CV)) %>% #Select only peptides detected in 3 replicates
    ggplot(aes( x = {{by}}, y = Area_CV))+
    geom_violin(aes( fill = {{by}}), alpha = 0.5, color = NA,
                width = 0.9, size = 0.2) +
    stat_boxplot(geom ='errorbar', width = 0.1, size = 0.2) + 
    geom_boxplot( width=0.2, outlier.alpha = 0, alpha = 0, size = 0.25, outliers = TRUE) +
    geom_hline(yintercept = 0.2, linetype = "dashed", alpha = 0.5) +
    stat_summary(fun.data = function(x) data.frame(y = cv_ylim, label=paste0("n = ", length(x))),
                 geom = "text", size = params$PlotTextLabelSize, vjust= 1.5) + #n = peptides IDed in all the replicates
    
    scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                       name = "Area %CV", breaks = seq(0, cv_ylim, by  = 0.25), limits = c(0, cv_ylim)) +
    theme_rawr +
    scale_fill_viridis_d(begin = 0, end = 1) +
    rotate_x_text(70) 
}


plot_corr <- function(mat){
  # plot correlation matrix, mat = output of cor()
  mat %>% 
    ggcorrplot(hc.order = FALSE) + 
    scale_x_discrete(limits=rev) +
    scale_y_discrete(limits=rev) +
    scale_fill_gradient2(low = "darkred", mid = "white", high = "darkblue", 
                         breaks= corrarea_breaks, 
                         limit= corrarea_lim, midpoint = corrarea_mid) + 
    theme(plot.background = element_rect(fill = "white")) +
    theme(plot.title = element_text(size = 8),
          axis.text.x = element_text(size = 6),
          axis.text.y = element_text(size = 6)) +
    rotate_x_text(65) 
}

if(exists("pviolin_areacv_cond_all")){
  pviolin_areacv_cond_all
}

ggprint_rawr <-function(input) {
  if(exists(deparse(substitute(input))) == TRUE){
    input
  }else{
    warning(paste0(deparse(substitute(input)), " was not generated"))
  }
}

get_mat_log2area <- function(input, row, col){
  # get the Log2Area in a matrix format, calculate mean if needed, e.g. when Condition is selected as column
  # rows = level used for rows, usually PeptideID or ProteinFirst
  ## NAs are kept as NA
  ordered_columns <- input %>%  pull({{col}}) %>%  levels() # get order from factor levels
  col_for_row_names <-  deparse(substitute(row)) #needs to be declared first
  input %>% #using mean of Log2area
    group_by({{row}}) %>% 
    filter(!all(is.na(Log2Area))) %>%  # avoid phantom IDs
    ungroup() %>% 
    pivot_wider(id_cols = {{row}}, values_from = Log2Area, names_from = {{col}}, values_fn = function(x) mean(x, na.rm = TRUE)) %>% 
    column_to_rownames(col_for_row_names) %>%
    select(all_of(ordered_columns)) %>% #order in function of levels
    as.matrix() 
}


check_ids_global <- function(input){
  # counts the total number of IDs, checking for decoys and conta
  input %>% 
    mutate(ProteinType = case_when(ProteinFirst == "" ~ "Not Assigned",
                                   grepl("#DECOY#", ProteinFirst, fixed =  TRUE) ~ "Decoy",
                                   grepl("_CONTA|CONTA_|Cont_", Accession, fixed =  FALSE) ~ "Contaminant",
                                   TRUE ~ "Assigned to Protein")) %>% 
    group_by(ProteinType) %>%  
    count_ids() %>% 
    rbind(input %>%  mutate(ProteinType = "Total") %>%   
            group_by(ProteinType)  %>% 
            count_ids()) %>% 
    mutate(prop_Peptides = round( n_Peptides/n_Peptides[ProteinType == "Total"], 3),
           prop_Sequences = round( n_Sequences/n_Sequences[ProteinType == "Total"], 3),
           prop_Proteins = round( n_Proteins/n_Proteins[ProteinType == "Total"], 3))
}
