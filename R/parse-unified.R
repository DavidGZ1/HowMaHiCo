# Dictionary-driven unified parser.
#
# Lets a user map an arbitrary tabular search-engine export onto the `pep_all`
# schema by editing a YAML dictionary, with no R coding and no new loader. The
# dictionary covers direct column renames, a `Found_By` constant, and the shared
# derived recipe every built-in loader applies (`Log2Area`, `Length_range`,
# `Nter`/`Cter`, `PeptideID`, `Charge` formatting). Software-specific transforms
# (unit conversions, regex extraction, accession splitting) are out of scope:
# pre-clean those before calling the parser. The three built-in loaders
# (FragPipe / DIA-NN / PEAKS) are unchanged; reference dictionaries documenting
# their directly-mappable subset ship in `inst/extdata/dictionaries/`.

`%||%` <- function(a, b) if (is.null(a)) b else a

#' Read and validate a HowMaHiCo parser dictionary
#'
#' Loads a YAML dictionary describing how to map a tabular search-engine export
#' onto the `pep_all` schema, fills in defaults, and validates the required
#' keys. See [parse_unified()] for the engine that consumes it and
#' [get_dictionary_template()] for a fill-in template.
#'
#' A dictionary has these keys:
#' * `found_by` — the `Found_By` label written into every row (required).
#' * `columns` — a `target: source` mapping (pep_all column : raw column);
#'   must cover at least `Sequence`, `Peptide`, `Area`, and `Length` (the last
#'   only when `derive.length_from_sequence` is not `true`).
#' * `mode` — `"individual_files"` (join on `Sample_fp`, default) or
#'   `"combined_file"` (join on `Sample_fp` + `Source_file`; then also map
#'   `Source_file`).
#' * `read$file` / `read$delim` — filename to read in each sample subfolder and
#'   its delimiter (defaults `"results.tsv"`, tab).
#' * `derive$length_from_sequence` — if `true`, `Length <- nchar(Sequence)`.
#' * `derive$format_charge` — if `true` (default), `Charge <- paste0("+ ", Charge)`.
#' * `derive$peptide_id` — column names pasted into `PeptideID`
#'   (default `c("ProteinFirst", "m_z", "Charge")`).
#'
#' @param path Path to a YAML dictionary file.
#'
#' @return The dictionary as a normalized list (defaults filled in).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' dict <- read_dictionary(
#'   system.file("extdata", "dictionaries", "fragpipe.yaml", package = "HowMaHiCo")
#' )
#' }
read_dictionary <- function(path) {
  if (!is.character(path) || length(path) != 1L) {
    stop("'path' must be a single path to a YAML dictionary file.")
  }
  if (!file.exists(path)) stop("Dictionary file not found: ", path)
  validate_dictionary(yaml::read_yaml(path))
}

#' Validate / normalize a dictionary list
#'
#' Internal: fills in defaults and checks the required keys for a dictionary
#' (whether read from YAML by [read_dictionary()] or passed as a list).
#'
#' @param dict A dictionary as a named list.
#'
#' @return The normalized dictionary list.
#'
#' @noRd
validate_dictionary <- function(dict) {
  if (!is.list(dict)) stop("A dictionary must be a list (or a YAML file parsed into one).")
  if (is.null(dict$columns) || !length(dict$columns)) {
    stop("Dictionary must define a non-empty 'columns:' mapping (target: source).")
  }
  if (is.null(dict$found_by) || !nzchar(as.character(dict$found_by))) {
    stop("Dictionary must define 'found_by:' (the Found_By label).")
  }

  dict$mode  <- dict$mode %||% "individual_files"
  if (!dict$mode %in% c("individual_files", "combined_file")) {
    stop("Dictionary 'mode:' must be 'individual_files' or 'combined_file', not '",
         dict$mode, "'.")
  }
  dict$read        <- dict$read %||% list()
  dict$read$file   <- dict$read$file %||% "results.tsv"
  dict$read$delim  <- dict$read$delim %||% "\t"
  dict$derive      <- dict$derive %||% list()
  dict$derive$length_from_sequence <- isTRUE(dict$derive$length_from_sequence)
  dict$derive$format_charge        <- dict$derive$format_charge %||% TRUE
  dict$derive$peptide_id <- as.character(unlist(
    dict$derive$peptide_id %||% c("ProteinFirst", "m_z", "Charge")))

  targets <- names(dict$columns)
  core    <- c("Sequence", "Peptide", "Area")
  if (!dict$derive$length_from_sequence) core <- c(core, "Length")
  miss <- setdiff(core, targets)
  if (length(miss)) {
    stop("Dictionary 'columns:' is missing required target(s): ",
         paste(miss, collapse = ", "),
         " (map them, or set derive.length_from_sequence: true to derive Length).")
  }
  if (dict$mode == "combined_file" && !"Source_file" %in% targets) {
    stop("mode: combined_file requires 'columns:' to map 'Source_file'.")
  }
  dict
}

#' Parse a raw search-engine export into `pep_all` via a dictionary
#'
#' The dictionary-driven counterpart of the built-in `parse_*()` loaders: applies
#' the `columns:` renames, sets the `Found_By` constant, and derives the shared
#' `pep_all` columns (`Length_range`, `Nter`/`Cter`, `Log2Area`, `PeptideID`, and
#' optionally `Length` and a formatted `Charge`), then guards the result with the
#' same `validate_pep_all()` schema check the built-in loaders use. Reuses
#' `compute_log2area()` so zero `Area` maps to `NA` consistently with the other
#' loaders.
#'
#' @param input A raw per-sample table, row-bound across samples and tagged with
#'   `Sample_fp` (e.g. the output of [read_custom_batch()]).
#' @param dictionary Either a path to a YAML dictionary or an already-loaded
#'   dictionary list (see [read_dictionary()]).
#' @param shortpep_range Length-2 numeric `c(min, max)` window for `Length_range`.
#'
#' @return The input reshaped into `pep_all` long format.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' dict <- system.file("extdata", "dictionaries", "fragpipe.yaml", package = "HowMaHiCo")
#' read_custom_batch("2_data/my_export", file = "psm.tsv", delim = "\t") |>
#'   parse_unified(dict, shortpep_range = c(8, 13))
#' }
parse_unified <- function(input, dictionary, shortpep_range = c(8, 13)) {
  dict <- if (is.character(dictionary)) read_dictionary(dictionary) else validate_dictionary(dictionary)

  rename_vec <- stats::setNames(unlist(dict$columns, use.names = FALSE), names(dict$columns))
  out <- input |>
    dplyr::select(dplyr::any_of("Sample_fp"), dplyr::any_of(rename_vec))

  # Fail loudly if a core source column was not present in the input.
  core_targets <- c("Sequence", "Peptide", "Area",
                    if (!dict$derive$length_from_sequence) "Length")
  miss <- setdiff(core_targets, names(out))
  if (length(miss)) {
    stop("These dictionary 'columns:' point to source columns not found in the input: ",
         paste(miss, collapse = ", "),
         ". Check the 'columns:' source names against the raw file's header.")
  }

  out <- out |> dplyr::mutate(Found_By = as.character(dict$found_by))

  if (dict$derive$length_from_sequence) {
    out$Length <- nchar(as.character(out$Sequence))
  }

  out <- out |>
    dplyr::mutate(
      Length = as.numeric(Length),
      Length_range = factor(dplyr::case_when(
        Length >= shortpep_range[1] & Length <= shortpep_range[2] ~
          paste0(shortpep_range[1], " to ", shortpep_range[2], " AAs"),
        Length < shortpep_range[1] | Length > shortpep_range[2] ~ "others")),
      Nter = as.factor(stringr::str_sub(Sequence, 1, 1)),
      Cter = as.factor(stringr::str_sub(Sequence, -1, -1)),
      Log2Area = compute_log2area(Area)
    )

  # PeptideID is built before Charge is reformatted, so a numeric Charge is
  # pasted as a bare integer (matching the built-in loaders' `as.numeric(Charge)`).
  id_cols <- dict$derive$peptide_id
  miss_id <- setdiff(id_cols, names(out))
  if (length(miss_id)) {
    stop("derive.peptide_id references column(s) not available after mapping: ",
         paste(miss_id, collapse = ", "), ".")
  }
  id_pieces <- lapply(id_cols, function(col) {
    v <- out[[col]]
    if (is.numeric(v)) v <- round(v, 1)
    as.character(v)
  })
  out$PeptideID <- do.call(paste, c(id_pieces, sep = "_"))

  if (isTRUE(dict$derive$format_charge) && "Charge" %in% names(out)) {
    out <- out |> dplyr::mutate(Charge = as.factor(paste0("+ ", Charge)))
  }

  validate_pep_all(out, as.character(dict$found_by))
}
