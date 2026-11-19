#' Precursor charge as a number
#'
#' `pep_all$Charge` is a factor of labels such as `"+ 2"`. `as.numeric()` on a
#' factor returns its level CODES, not the charges, so a dataset with no 1+
#' precursors would read 2+ as 1, 3+ as 2, and so on. This parses the digits
#' out of the label instead, and also accepts a plain number.
#'
#' @param x Charge vector (factor, character or numeric).
#'
#' @return Numeric vector of charges (`NA` where no number can be read).
#'
#' @noRd
.charge_number <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(gsub("[^0-9]", "", as.character(x))))
}

# Internal helpers shared by the FragPipe / DIA-NN / PEAKS loaders.
# Keeping the shared logic in one place means the three loader families stay
# consistent (same zero-Area semantics, same run-name extraction, same
# guaranteed output schema) instead of each re-implementing it.

#' Compute log2(Area), mapping a zero Area to a chosen sentinel
#'
#' `log2(0)` is `-Inf`, which breaks downstream correlation / %CV maths. All
#' three loaders route their `Area`/`Intensity` column through this helper so
#' that a zero maps to the same value everywhere. `NA` is the default (a true
#' zero has no defined log; it should be missing, not a fabricated finite
#' number).
#'
#' @param area Numeric vector of areas / intensities.
#' @param zero_to Value substituted where `area == 0` (default `NA_real_`).
#'
#' @return Numeric vector of `log2(area)`, with zeros replaced by `zero_to`.
#'
#' @noRd
compute_log2area <- function(area, zero_to = NA_real_) {
  ifelse(area == 0, zero_to, log2(area))
}

#' Extract a run name from a file path, regardless of path separator
#'
#' Search engines write the acquisition file path using whatever separator the
#' acquisition machine used (`\\` on Windows, `/` on Linux/macOS). This helper
#' normalises both, takes the final path element, and drops its extension — so
#' run-name extraction works identically on every OS (including inside a Linux
#' Docker image), unlike a backslash-anchored regex.
#'
#' @param path Character vector of file paths (e.g. DIA-NN `File.Name`, a
#'   HyStar `Result.Path` ending in a Bruker `.d` folder).
#'
#' @return Character vector of run names (basename without extension).
#'
#' @noRd
extract_run_name <- function(path) {
  tools::file_path_sans_ext(basename(gsub("\\\\", "/", path)))
}

#' Validate that a parsed table carries the core `pep_all` schema
#'
#' Called at the tail of each `parse_*()` so a loader that silently drops or
#' renames a core column (or returns an empty frame) fails loudly at the source
#' rather than producing a half-broken report several sections later.
#'
#' @param df A parsed loader output (one row per peptide-sample observation).
#' @param software Loader label, used only in the error message.
#'
#' @return `df` invisibly, if valid; otherwise stops with a descriptive error.
#'
#' @noRd
validate_pep_all <- function(df, software = "unknown") {
  required <- c("Peptide", "Sequence", "Length", "Area", "Log2Area",
                "Length_range", "Found_By", "PeptideID")
  missing <- setdiff(required, names(df))
  if (length(missing)) {
    stop(sprintf("%s loader output is missing required column(s): %s",
                 software, paste(missing, collapse = ", ")))
  }
  if (nrow(df) == 0L) {
    stop(sprintf("%s loader produced an empty table (0 rows)", software))
  }
  numeric_cols <- c("Length", "Area", "Log2Area")
  non_numeric <- numeric_cols[!vapply(df[numeric_cols], is.numeric, logical(1))]
  if (length(non_numeric)) {
    stop(sprintf("%s loader output has non-numeric column(s): %s",
                 software, paste(non_numeric, collapse = ", ")))
  }
  invisible(df)
}

#' Reduce a raw search-engine table to a minimal, representative test dataset
#'
#' `TestMode` used to be implemented as `read_tsv(n_max = 100)`, which is fine
#' for one-file-per-sample exports but breaks the combined ones: a FragPipe
#' `fragpipe_dda_combined` `psm.tsv` holds every run, so the first 100 lines come
#' from the first run or two and every other annotated run silently disappears --
#' the annotation join then drops most samples and the report falls apart
#' (single Condition, no replicates, empty correlations).
#'
#' This instead keeps the first `n` rows **per run**, so every run/Condition/
#' replicate of the experiment survives at ~1/1000 of the size. The run column is
#' auto-detected: `Run` (DIA-NN), else the run part of `Spectrum` (FragPipe,
#' `run1.123.123.2` -> `run1`); with neither, the first `n` rows overall are kept.
#'
#' @param input Raw data frame as read from disk.
#' @param n Rows to keep per run. Default `100`.
#'
#' @return `input`, subset to at most `n` rows per run, in the original row order.
#'
#' @noRd
subsample_testmode <- function(input, n = 100L) {
  if (nrow(input) == 0) return(input)

  run <- if ("Run" %in% names(input)) {
    as.character(input[["Run"]])
  } else if ("Spectrum" %in% names(input)) {
    sub("[.].*", "", as.character(input[["Spectrum"]]))
  } else {
    NULL
  }
  if (is.null(run)) return(utils::head(input, n))

  idx <- unlist(lapply(split(seq_len(nrow(input)), run), function(i) utils::head(i, n)),
                use.names = FALSE)
  input[sort(idx), , drop = FALSE]
}
