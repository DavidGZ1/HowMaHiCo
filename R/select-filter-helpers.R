#' Select distinct rows on a subset of columns
#'
#' Shorthand for `select(...) %>% unique() %>% droplevels()` — used to build
#' the small per-comparison data frames consumed by [plot_upset_batch()] and
#' similar overlap helpers.
#'
#' @param input A data frame.
#' @param ... Columns to select, forwarded to [dplyr::select()] (tidy
#'   evaluation).
#'
#' @return `input` restricted to the selected columns, with duplicate rows
#'   removed and unused factor levels dropped.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' select_unique(pep_all, Condition, Sequence)
#' }
select_unique <- function(input, ...){
  input %>%
    dplyr::select(...) %>%
    unique() %>%
    droplevels()
}

#' Filter rows and drop to distinct/unused-level state
#'
#' Shorthand for `filter(...) %>% unique() %>% droplevels()` — the filtering
#' counterpart to [select_unique()], used to restrict a `pep_all`-shaped data
#' frame to one `Condition`/`Sample_type`/... before batch-plotting its
#' overlap.
#'
#' @param input A data frame.
#' @param ... Filtering conditions, forwarded to [dplyr::filter()] (tidy
#'   evaluation).
#'
#' @return `input` restricted to the matching rows, with duplicate rows
#'   removed and unused factor levels dropped.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' filter_unique(pep_all, Condition == "JY")
#' }
filter_unique <- function(input, ...){
  input %>%
    dplyr::filter(...) %>%
    unique() %>%
    droplevels()
}
