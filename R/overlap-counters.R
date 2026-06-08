#' Count distinct elements shared between two conditions
#'
#' @param input A `pep_all`-shaped data frame with `Condition` and `variable`
#'   columns.
#' @param variable Name (string) of the column whose distinct values are
#'   compared, e.g. `"Peptide"`.
#' @param cond1,cond2 The two `Condition` levels to compare.
#'
#' @return The number of distinct `variable` values present in both `cond1`
#'   and `cond2`.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' count_intersect(pep_all, variable = "Peptide", cond1 = "JY", cond2 = "Plasma")
#' }
count_intersect <- function(input, variable, cond1, cond2){
  a <- input[input$Condition == cond1, variable]
  b <- input[input$Condition == cond2, variable]
  dplyr::n_distinct(intersect(a, b))
}

#' Count distinct elements across the union of two conditions
#'
#' Counterpart to [count_intersect()] — used together to derive the
#' overlap/total ratio for a pair of conditions.
#'
#' @inheritParams count_intersect
#'
#' @return The number of distinct `variable` values present in `cond1` and/or
#'   `cond2` combined.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' count_merged(pep_all, variable = "Peptide", cond1 = "JY", cond2 = "Plasma")
#' }
count_merged <- function(input, variable, cond1, cond2){
  a <- input[input$Condition == cond1, variable]
  b <- input[input$Condition == cond2, variable]
  dplyr::n_distinct(c(a, b))
}

#' Count distinct entries in one or more variables, grouped by other variables
#'
#' @param df A data frame.
#' @param vars Column(s) (tidy-evaluated) whose distinct entries are counted,
#'   e.g. `Sample` or `c(Sample, Patient)`.
#' @param by Column(s) (tidy-evaluated) to group by.
#' @param total Logical; if `TRUE`, an extra set of rows is appended with every
#'   `by` column collapsed to `"Total"`, giving an overall count alongside the
#'   per-group ones.
#' @param sep Separator used when building the output column names
#'   (`"<fn><sep><col>"`, e.g. `"n_Sample"`).
#'
#' @return A data frame with one row per `by`-group (plus, if `total = TRUE`,
#'   one `"Total"` row) and `n_<vars>`-named columns of distinct counts.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' count_uniqueby(pep_all, vars = Sample, by = Condition, total = TRUE)
#' }
count_uniqueby <- function(df, vars, by, total = FALSE, sep = "_"){
  count_by <- df %>%
    dplyr::group_by(dplyr::across({{ by }})) %>%
    dplyr::summarise(dplyr::across({{ vars }}, list(n = dplyr::n_distinct),
                                   .names = paste0("{fn}", sep, "{col}")),
                     .groups = "drop")
  if(total == TRUE){
    count_total <- df %>%
      dplyr::mutate(dplyr::across({{ by }}, ~ sub(.x, pattern = ".*", replacement = "Total"))) %>%
      dplyr::group_by(dplyr::across({{ by }})) %>%
      dplyr::summarise(dplyr::across({{ vars }}, list(n = dplyr::n_distinct),
                                     .names = paste0("{fn}", sep, "{col}")),
                       .groups = "drop")
    count_by <- rbind(count_by, count_total)
  }
  return(count_by)
}

#' Count samples/patients per peptide or protein, pivoted wide by group
#'
#' Wraps [count_uniqueby()] for the common `pep_all` "how many samples/
#' patients was this peptide/protein seen in, per group" question: groups by
#' `var` within `by` plus the identity columns appropriate for `level`, then
#' pivots so each `by` level becomes its own `n_<var>s.<by level>` column.
#'
#' @param input A `pep_all`-shaped data frame.
#' @param var Column (tidy-evaluated) to count distinct entries of, e.g.
#'   `Sample` or `Patient`.
#' @param by Column (tidy-evaluated) whose levels become the pivoted-wide
#'   columns, e.g. `Condition` or `Sample_type`.
#' @param level One of `"Peptide"` (groups by `Accession`, `ProteinFirst`,
#'   `GeneFirst`, `OrganismFirst`, `Length`, `Peptide`, `Sequence`) or
#'   `"Protein"` (groups by `Accession`, `ProteinFirst`, `GeneFirst`,
#'   `OrganismFirst` only — `ProteinFirst`/`GeneFirst` are deliberately
#'   excluded from the `"Peptide"` grouping key beyond what's listed because
#'   some peptides were assigned to different `ProteinFirst` values across
#'   processing runs despite sharing `Accession`/`Sequence`).
#'
#' @return A wide data frame, one row per `level`-appropriate identity group,
#'   with `n_<var>s.<by level>` count columns (zero-filled where absent).
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' count_uniqueby_ip(pep_all, var = Sample, by = Condition, level = "Peptide")
#' }
count_uniqueby_ip <- function(input, var, by, level = "Peptide"){
  if(level == "Peptide"){
    key_columns <- c("Accession", "ProteinFirst", "GeneFirst", "OrganismFirst", "Length", "Peptide", "Sequence")
  }
  if(level == "Protein"){
    key_columns <- c("Accession", "ProteinFirst", "GeneFirst", "OrganismFirst")
  }
  input %>%
    count_uniqueby(vars = {{ var }},
                   by = c({{ by }}, dplyr::all_of(key_columns))) %>%
    tidyr::pivot_wider(id_cols = dplyr::all_of(key_columns),
                       names_from = {{ by }}, values_from = dplyr::starts_with("n_"),
                       names_glue = "{.value}s.{.name}", values_fill = 0) %>%
    dplyr::arrange(dplyr::pick(key_columns))
}

#' Combined per-Patient/Sample_type/Condition sample-and-patient count summary
#'
#' Runs [count_uniqueby_ip()] five times (totals across all samples, totals
#' across all patients, by `Patient`, by `Sample_type`, by `Condition`) and
#' column-binds the results into one wide summary table — after checking that
#' every variant produced rows in the same identity-key order (otherwise the
#' `cbind()` would silently misalign).
#'
#' @param input A `pep_all`-shaped data frame with `Patient`/`Sample_type`/
#'   `Condition`/`Sample` columns (the project-specific patient-cohort
#'   annotation columns this summary was designed around).
#' @param level Forwarded to [count_uniqueby_ip()] (`"Peptide"` or
#'   `"Protein"`).
#'
#' @return A wide data frame: identity columns (per `level`) followed by every
#'   `n_*` count column from each of the five summaries.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' count_samples_patients(pep_all, level = "Peptide")
#' }
count_samples_patients <- function(input, level){
  counts_total_samples <- count_uniqueby_ip(dplyr::mutate(input, Condition = "Total"),
                                            var = Sample, by = Condition, level)
  counts_total_patients <- count_uniqueby_ip(dplyr::mutate(input, Condition = "Total"),
                                             var = Patient, by = Condition, level)
  counts_patient <- count_uniqueby_ip(input, var = Sample, by = Patient, level)
  counts_type <- count_uniqueby_ip(input, var = Patient, by = Sample_type, level)
  counts_condition <- count_uniqueby_ip(input, var = Sample, by = Condition, level)

  if(level == "Peptide"){
    key_columns <- c("Accession", "ProteinFirst", "GeneFirst", "OrganismFirst", "Length", "Peptide", "Sequence")
  }
  if(level == "Protein"){
    key_columns <- c("Accession", "ProteinFirst", "GeneFirst", "OrganismFirst")
  }
  key_info <- counts_condition[, key_columns]
  if(all(key_info == counts_total_patients[, key_columns], na.rm = TRUE) &
     all(key_info == counts_total_samples[, key_columns], na.rm = TRUE) &
     all(key_info == counts_patient[, key_columns], na.rm = TRUE) &
     all(key_info == counts_type[, key_columns], na.rm = TRUE)){
    output <-
      cbind(
        key_info,
        counts_total_samples %>% dplyr::select(dplyr::starts_with("n_")),
        counts_total_patients %>% dplyr::select(dplyr::starts_with("n_")),
        counts_type %>% dplyr::select(dplyr::starts_with("n_")),
        counts_patient %>% dplyr::select(dplyr::starts_with("n_")),
        counts_condition %>% dplyr::select(dplyr::starts_with("n_"))
      )
  }else{
    stop("data in key_columns is not the same, check if they were ordered correctly")
  }
  return(output)
}
