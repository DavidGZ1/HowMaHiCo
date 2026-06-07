#' Count distinct peptides, sequences, and proteins
#'
#' @param input A `pep_all`-shaped data frame (or any grouped subset of one)
#'   with `Peptide`/`Sequence`/`Accession` columns.
#'
#' @return A one-row (or one-row-per-group, if `input` is grouped) data frame
#'   with `n_Peptides`, `n_Sequences`, `n_Proteins`.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' count_ids(pep_all)
#' }
count_ids <- function(input){
  input %>%
    dplyr::summarise(n_Peptides = dplyr::n_distinct(Peptide, na.rm = TRUE),
                     n_Sequences = dplyr::n_distinct(Sequence, na.rm = TRUE),
                     n_Proteins = dplyr::n_distinct(Accession, na.rm = TRUE),
                     .groups = "drop")

}

#' ID counts and proportions by `Length_range` and `Condition`
#'
#' Computes peptide/sequence/protein counts for each `Condition` ×
#' `Length_range` combination (plus an `"All peptides"` total row per
#' `Condition`), pivots to long format, and derives the proportion,
#' percentage, and cumulative proportion/count of each `Length_range` class
#' relative to its condition's total — the table consumed by
#' [plot_prop_length_condition()].
#'
#' Defines its own internal `count_ids(input, ..., total = FALSE)` helper
#' (grouping on arbitrary `...` columns, with an optional synthetic `"Total"`
#' row) — note this **shadows** the package's simpler [count_ids()] for the
#' duration of this function only; the two serve different call patterns and
#' were kept distinct rather than unified, to stay faithful to the original
#' "imported from functions_thunder" implementation.
#'
#' @param input A `pep_all`-shaped data frame with `Condition`, `Length_range`,
#'   `Peptide`, `Sequence`, `Accession` columns.
#'
#' @return A long-format data frame of counts/proportions/percentages per
#'   `Condition` × `Length_range` × `Level` (`Peptides.Modified`/`Peptides`/
#'   `Proteins`), with `Length_range` factor-ordered for stacked-bar plotting.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' count_ids_condition_bylengthrange(pep_all)
#' }
count_ids_condition_bylengthrange <- function(input){
  # count_ids from thunder, works differently to the other one above
  count_ids <- function(input, ..., total = FALSE){
    # count distinct entries for Modified_Peptides.Modified, Peptides.Modified and Proteins
    # input = a dataframe of PEAKS formated peptide result
    # total = logical, if TRUE a row with totals is included
    # ... = variable(s) to be used for grouping
    counts_ids <- input %>%
      dplyr::group_by(...) %>%
      dplyr::summarise(n_Peptides.Modified = dplyr::n_distinct(Peptide, na.rm = TRUE),
                       n_Peptides = dplyr::n_distinct(Sequence, na.rm = TRUE),
                       n_Proteins = dplyr::n_distinct(Accession, na.rm = TRUE),
                       .groups = "drop")

    if(total == TRUE){
      count_total <-
        input %>%
        dplyr::mutate(dplyr::across(c(...), ~ sub(.x, pattern = ".*", replacement = "Total"))) %>%
        dplyr::group_by(...) %>%
        dplyr::summarise(n_Peptides.Modified = dplyr::n_distinct(Peptide, na.rm = TRUE),
                         n_Peptides = dplyr::n_distinct(Sequence, na.rm = TRUE),
                         n_Proteins = dplyr::n_distinct(Accession, na.rm = TRUE),
                         .groups = "drop")

      counts_ids <- rbind(counts_ids, count_total)
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
    dplyr::bind_rows(count_ids(input, Condition) %>%
                       dplyr::mutate(Length_range = "All peptides"),
                     count_ids(input, Condition, Length_range)) %>%
    # arrange factors in a logical way
    dplyr::mutate(Length_range = factor(Length_range,
                                        levels = c("All peptides", rev(levels_length))))

  ## Proportion in absolute numbers
  prop_by_length_total <-
    counts_by_length_total %>%
    tidyr::pivot_longer(cols = dplyr::starts_with("n_"), names_to = "Level", values_to = "Count", names_prefix = "n_") %>%
    dplyr::group_by(Condition, Level) %>%
    dplyr::mutate(Proportion = round(Count / Count[Length_range == "All peptides"], 2),
                  Percentage = paste0(Proportion * 100, "%")) %>%
    dplyr::arrange(Condition, Level, dplyr::desc(Length_range)) %>% # this may messup with order for plots
    dplyr::mutate(CumProportion = cumsum(Proportion), # this may messup with order for plots
                  CumCount = cumsum(Count),
                  CumCount = ifelse(Length_range != "All peptides",
                                    CumCount - Count[Length_range == "All peptides"],
                                    Count)) %>%
    dplyr::ungroup()

  return(prop_by_length_total)
}

#' Classify charge states into `+1`/`+2`/`>= +3` groups
#'
#' @param input A `pep_all`-shaped data frame with a `Charge` column
#'   (coercible to numeric, e.g. the `"+ 2"`-style factor produced by the
#'   loaders).
#'
#' @return `input` with `Charge` coerced to numeric and a new `Charge_group`
#'   factor column (`"+ 1"`, `"+ 2"`, `">= +3"`).
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' get_charge_group(pep_all)
#' }
get_charge_group <- function(input){
  input %>%
    dplyr::mutate(Charge = as.numeric(Charge)) %>%
    dplyr::mutate(Charge_group = factor(dplyr::case_when(Charge < 3 ~ paste0("+ ", Charge),
                                                          TRUE ~ "\u2265 +3"),
                                        c("+ 1", "+ 2", "\u2265 +3")))
}

#' Proportions of each charge group within a count table
#'
#' Pivots a wide `n_*` count table to long format and computes, within each
#' `Condition` × `Level` group, the proportion/percentage/cumulative
#' proportion of each `Charge_group` relative to its `"Total"` row — the table
#' consumed by [plot_charge_proportions()].
#'
#' @param df A count data frame with `Condition`, `Charge_group`, and one or
#'   more `n_*`-prefixed count columns, including a `"Total"` `Charge_group`
#'   row per `Condition`.
#'
#' @return `df` reshaped to long format with added `Level`, `Count`,
#'   `Proportion`, `Percentage`, `CumProportion` columns.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' get_proportion_charge(counts_charge_condition)
#' }
get_proportion_charge <- function(df){
  df %>%
    tidyr::pivot_longer(cols = dplyr::starts_with("n_"), names_to = "Level", values_to = "Count", names_prefix = "n_") %>%
    dplyr::group_by(Condition, Level) %>%
    dplyr::mutate(Proportion = round(Count / Count[Charge_group == "Total"], 3),
                  Percentage = paste0(Proportion * 100, "%")) %>%
    dplyr::arrange(Condition, Level, dplyr::desc(Charge_group)) %>%
    dplyr::mutate(CumProportion = cumsum(Proportion) - 1) %>%
    dplyr::ungroup()
}

#' Wide table of peptide identifications by an arbitrary grouping
#'
#' Counts the number of distinct samples in which each peptide was identified,
#' grouped by `...` plus the standard identity columns, then pivots to one
#' column per `Condition` (`n_Samples.<Condition>`).
#'
#' @param input A `pep_all`-shaped data frame.
#' @param ... Additional grouping variable(s) (besides `Condition`,
#'   `Accession`, `ProteinFirst`, `GeneFirst`, `Length`, `Peptide`,
#'   `Sequence`), forwarded to [dplyr::group_by()].
#'
#' @return A wide data frame, one row per peptide, with `n_Samples.<Condition>`
#'   columns giving the number of samples it was seen in for each condition.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' count_ids_by(pep_all, BioReplicate)
#' }
count_ids_by <- function(input, ...){
  input %>%
    dplyr::group_by(..., Accession, ProteinFirst, GeneFirst, Length, Peptide, Sequence) %>%
    dplyr::summarise(n_Samples = dplyr::n_distinct(Sample),
                     .groups = "drop") %>%
    tidyr::pivot_wider(id_cols = c(Accession, ProteinFirst, GeneFirst, Length, Peptide, Sequence),
                       names_from = Condition, values_from = c(n_Samples),
                       names_prefix = "n_Samples.", names_sep = ".", values_fill = 0) %>%
    dplyr::arrange(Accession, ProteinFirst, GeneFirst, Length, Peptide, Sequence)
}

#' Per-peptide Area mean/sd/%CV summary by group
#'
#' @param input A `pep_all`-shaped data frame with `Accession`, `Peptide`,
#'   `Charge`, `Area` columns.
#' @param by Additional grouping variable (e.g. `Condition`, `BioReplicate`),
#'   used with tidy evaluation.
#'
#' @return A data frame with one row per `Accession`/`Peptide`/`Charge`/`by`
#'   group and columns `Count`, `Area_mean`, `Area_sd`, `Area_CV`,
#'   `Area_CV_perc`.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' summarise_area(pep_all, Condition)
#' }
summarise_area <- function(input, by){
  input %>%
    dplyr::group_by(Accession, Peptide, Charge, {{ by }}) %>%
    dplyr::summarise(Count = sum(!is.na(Area)),
                     Area_mean = mean(Area, na.rm = TRUE),
                     Area_sd = sd(Area, na.rm = TRUE),
                     Area_CV = Area_sd / Area_mean,
                     Area_CV_perc = Area_CV * 100,
                     .groups = "drop") %>%
    dplyr::ungroup()
}

#' List unique peptide sequences per group
#'
#' @param input A `pep_all`-shaped data frame with a `Sequence` column.
#' @param by Column name (string) to split by, e.g. `"Condition"`.
#'
#' @return A named list of character vectors, one per level of `by`, each
#'   containing that group's unique non-empty sequences.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' list_sequences(pep_all, "Condition")
#' }
list_sequences <- function(input, by){
  input_min <- input %>% dplyr::select(dplyr::all_of(by), Sequence) %>%
    unique %>% droplevels # we need only the unique sequences
  lapply(split(input_min[-1], input_min[, by]), function(x) x[x != ""])
}

#' Build a `Log2Area` matrix for clustering/heatmaps/correlation
#'
#' Pivots `input` to a wide `row` × `col` matrix of (mean, if needed)
#' `Log2Area` values, dropping rows that are entirely `NA` ("phantom IDs") and
#' ordering columns by the factor levels of `col`.
#'
#' @param input A `pep_all`-shaped data frame with `Log2Area` and the columns
#'   named by `row`/`col`.
#' @param row Column to use for matrix rows (tidy-evaluated; usually
#'   `PeptideID` or `ProteinFirst`).
#' @param col Column to use for matrix columns (tidy-evaluated; must be a
#'   factor — its levels set the column order, e.g. `Sample` or `Condition`).
#'   When several rows share the same `col` value, their `Log2Area` values are
#'   averaged (`na.rm = TRUE`).
#'
#' @return A numeric matrix with `NA`s preserved, rows named by `row` and
#'   columns ordered by the factor levels of `col`.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' get_mat_log2area(pep_all, PeptideID, Sample)
#' }
get_mat_log2area <- function(input, row, col){
  ordered_columns <- input %>% dplyr::pull({{ col }}) %>% levels() # get order from factor levels
  col_for_row_names <- deparse(substitute(row)) # needs to be declared first
  input %>% # using mean of Log2area
    dplyr::group_by({{ row }}) %>%
    dplyr::filter(!all(is.na(Log2Area))) %>% # avoid phantom IDs
    dplyr::ungroup() %>%
    tidyr::pivot_wider(id_cols = {{ row }}, values_from = Log2Area, names_from = {{ col }}, values_fn = function(x) mean(x, na.rm = TRUE)) %>%
    tibble::column_to_rownames(col_for_row_names) %>%
    dplyr::select(dplyr::all_of(ordered_columns)) %>% # order in function of levels
    as.matrix()
}

#' Total ID counts split by protein/decoy/contaminant assignment
#'
#' Classifies every row as `"Decoy"`, `"Contaminant"`, `"Not Assigned"`, or
#' `"Assigned to Protein"` (based on `ProteinFirst`/`Accession`), counts IDs
#' within each class plus an overall `"Total"` row, and adds the proportion of
#' the total each class represents.
#'
#' @param input A `pep_all`-shaped data frame with `ProteinFirst`, `Accession`,
#'   `Peptide`, `Sequence` columns.
#'
#' @return A data frame with one row per `ProteinType` (plus `"Total"`) and
#'   columns `n_Peptides`/`n_Sequences`/`n_Proteins` and their `prop_*`
#'   proportions of the total.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' check_ids_global(pep_all)
#' }
check_ids_global <- function(input){
  input %>%
    dplyr::mutate(ProteinType = dplyr::case_when(ProteinFirst == "" ~ "Not Assigned",
                                                  grepl("#DECOY#", ProteinFirst, fixed = TRUE) ~ "Decoy",
                                                  grepl("_CONTA|CONTA_|Cont_", Accession, fixed = FALSE) ~ "Contaminant",
                                                  TRUE ~ "Assigned to Protein")) %>%
    dplyr::group_by(ProteinType) %>%
    count_ids() %>%
    rbind(input %>% dplyr::mutate(ProteinType = "Total") %>%
            dplyr::group_by(ProteinType) %>%
            count_ids()) %>%
    dplyr::mutate(prop_Peptides = round(n_Peptides / n_Peptides[ProteinType == "Total"], 3),
                  prop_Sequences = round(n_Sequences / n_Sequences[ProteinType == "Total"], 3),
                  prop_Proteins = round(n_Proteins / n_Proteins[ProteinType == "Total"], 3))
}
