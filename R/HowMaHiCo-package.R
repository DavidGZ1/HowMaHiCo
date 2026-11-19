#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import dplyr
#' @import ggplot2
#' @import tidyr
#' @import stringr
#' @importFrom graphics par
#' @importFrom stats cutree density dist hclust sd
#' @importFrom utils read.csv stack write.csv
## usethis namespace: end
NULL

# Column/group names referenced unquoted inside dplyr/tidyr/ggplot2 NSE
# (mutate(), aes(), summarise(), case_when(), select_unique(var = ...), ...)
# throughout R/ -- not missing imports, just how tidy-eval column references
# read to a static parser. Declaring them here silences "no visible binding
# for global variable" NOTEs in R CMD check without rewriting ~40 functions'
# worth of pipelines to the .data[[...]]/.data$... pronoun. ("var" here is
# plot_upset_batch's grouping-column argument, not stats::var.)
utils::globalVariables(c(
  ".", "..density..",
  "Accession", "AccessionFirst", "All.Mapped.Genes", "All.Mapped.Proteins",
  "Area", "Area_CV", "Area_mean", "Area_sd", "Assigned_Modifications",
  "Average", "Averagine",
  "BioReplicate",
  "CScore", "CV", "Calculated_M.Z", "Calibrated_Observed_M.Z", "Calibrated_Observed_Mass",
  "Charge", "Charge_group", "Condition", "Count", "Cter", "CumCount", "CumProportion",
  "Decoy.CScore", "Decoy.Evidence",
  "Entry_Name", "Evidence",
  "File.Name", "File_peaks_nb", "Folder", "Found_By", "Fraction_peaks",
  "Fragment.Correlations", "Fragment.Info", "Fragment.Quant.Corrected", "Fragment.Quant.Raw",
  "GG.Q.Value", "Gene", "GeneFirst", "Genes", "Genes.MaxLFQ", "Genes.MaxLFQ.Unique",
  "Genes.Normalised", "Genes.Quantity", "Global.PG.Q.Value", "Global.Q.Value",
  "Hyperscore",
  "IM", "Intensity", "Ion_Mobility", "Is_Contaminant", "Is_Decoy", "Is_Unique",
  "Length", "Length_range", "Level", "Lib.Index", "Lib.PG.Q.Value", "Lib.Q.Value",
  "Log2Area",
  "MS2.Scan", "Mapped_Genes", "Mapped_Proteins", "Mass", "Mass.Evidence", "Metric",
  "Modified.Sequence", "Modified_Peptide", "Ms1.Area", "Ms1.Profile.Corr", "Ms1.Translated",
  "Nextscore", "Nter",
  "OrganismFirst",
  "PEP", "PG.MaxLFQ", "PG.Normalised", "PG.Q.Value", "PG.Quantity", "PTM", "Patient",
  "Peptide", "PeptideID", "Peptide_Length", "Percentage",
  "Precursor.Charge", "Precursor.Id", "Precursor.Mz", "Precursor.Normalised",
  "Precursor.Quantity", "Precursor.Translated",
  "Predicted.IM", "Predicted.RT", "Predicted.iIM", "Predicted.iRT",
  "Probability", "Project", "Proportion", "Protein", "Protein.Group", "Protein.Ids",
  "Protein.Names", "Protein.Q.Value", "ProteinFirst", "ProteinType", "Protein_Description",
  "Protein_ID", "Proteotypic",
  "Q.Value", "QC", "Quantity.Quality", "Qvalue",
  "RT", "RT.Start", "RT.Stop", "Retention", "Run",
  "Sample", "Sample_ID", "Sample_folder", "Sample_fp", "Sample_peaks", "Sample_type", "Sequence",
  "Source_File", "Source_file", "Spectrum", "Spectrum.Similarity", "Spectrum_File",
  "Stripped.Sequence",
  "TechReplicate", "Total", "Translated.Q.Value", "Translated.Quality", "Type",
  "X", "X.1", "X1_k0_Range", "X_10lgP",
  "found",
  "iIM", "iRT", "invk0_end", "invk0_start",
  "m_z",
  "n", "n_Peptides", "n_Proteins", "n_Samples", "n_Sequences",
  "path_full", "ppm",
  "metric", "region", "res_file", "score", "var",
  ":=", "Result.Path", "Sample.Comment", "in_range", "ind", "values",
  # quant-stats engine and its plots (R/quant-stats.R, plot_* in R/plots.R)
  "AveExpr", "Contrast", "Detected", "Exclusive_in", "Feature", "Feature_",
  "Loading", "P.Value", "P.Value_det", "PCx", "PCy", "Rank", "Status", "Unit",
  "Unit_", "Value", "Variance", "adj.P.Val", "adj.P.Val_det", "logFC",
  "n_det_ref", "n_det_test", "n_tot_ref", "n_tot_test", "n_units", "PC", "x", "y",
  # pepchem engine and its plots (R/pepchem.R, plot_* in R/plots.R)
  "AA", "CliffsDelta", "Flag", "Frequency", "Group", "Log2Enrichment",
  "Log2Ratio", "Property", "p_adj",
  # prot-all engine and its plots (R/prot-all.R, plot_* in R/plots.R)
  "Protein", "Protein_", "Protein_shared", "Peptide_unique_", "n_Detected",
  "n_Peptides_total", "n_Proteins",
  # cross-run comparison and the overview red flags (R/compare-runs.R,
  # R/quality-score.R, plot_run_trend in R/plots.R)
  "value", "is_QC", "Colour", "Detail", "Severity",
  # pre-existing NSE names that R CMD check still listed as undefined
  "invk0", "invk0_bin", "perc_num"
))
