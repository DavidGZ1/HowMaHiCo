# Small helpers shared by the report templates
#
# These exist so that a value used by several skeletons (the MHC length window,
# its palette, the list of condition pairs) is defined ONCE in the package
# instead of being copy-pasted into every Rmd: the windows used to live in three
# duplicated `mhcclass_ranges` lists plus a fourth hard-coded copy inside
# .cross_class_range(), which is exactly how a new class (mouse MHC-I) would
# otherwise have to be added in four places.

#' Peptide-length window of an MHC class
#'
#' Single source of truth for the "selected peptides" (`pep_short`) length
#' window used by every report template and by the quality-score engine.
#'
#' The built-in classes are the canonical ligand-length windows:
#' `"MHC1"` 8-13 AAs (human HLA-I), `"MHC1_mouse"` **7-11 AAs** (murine H-2, whose
#' ligands run shorter — H-2Kb favours 8-mers), and `"MHC2"` 12-25 AAs. Any other
#' value falls back to the explicit `min`/`max` arguments, which is how the
#' `ShortPeptideLengthMin`/`ShortPeptideLengthMax` report params take over for a
#' custom window.
#'
#' @param mhcclass One of `"MHC1"` (default), `"MHC1_mouse"`, `"MHC2"`, or any
#'   other string to use the custom `min`/`max` window.
#' @param min,max Custom window bounds, used only when `mhcclass` is not one of
#'   the built-in classes.
#'
#' @return An integer vector `c(lo, hi)`.
#'
#' @export
#'
#' @examples
#' mhc_length_window("MHC1")
#' mhc_length_window("MHC1_mouse")
#' mhc_length_window("custom", min = 9, max = 11)
mhc_length_window <- function(mhcclass = "MHC1", min = NULL, max = NULL) {
  windows <- list(MHC1 = c(8L, 13L), MHC1_mouse = c(7L, 11L), MHC2 = c(12L, 25L))
  if (!is.null(mhcclass) && length(mhcclass) == 1 && mhcclass %in% names(windows))
    return(windows[[mhcclass]])

  if (is.null(min) || is.null(max) || is.na(min) || is.na(max)) {
    warning("mhc_length_window(): unknown MHCclass '", mhcclass,
            "' and no custom min/max given; falling back to the MHC1 window (8-13 AAs).",
            call. = FALSE)
    return(windows$MHC1)
  }
  c(as.integer(min), as.integer(max))
}

#' Names of the built-in MHC classes
#'
#' The `mhcclass` values [mhc_length_window()] and [mhc_class_palette()] know
#' about, in the order they are offered in the report templates.
#'
#' @return A character vector.
#'
#' @export
#'
#' @examples
#' mhc_classes()
mhc_classes <- function() c("MHC1", "MHC1_mouse", "MHC2")

#' Two-colour fill palette of an MHC class
#'
#' The selected-vs-other length fill used across the report plots. `"MHC1_mouse"`
#' shares the `"MHC1"` palette (the same class, a different species); an
#' unrecognised class also falls back to it.
#'
#' @param mhcclass One of `"MHC1"`, `"MHC1_mouse"`, `"MHC2"`.
#'
#' @return A length-2 character vector of hex colours, `c(in_window, other)`.
#'
#' @export
#'
#' @examples
#' mhc_class_palette("MHC2")
mhc_class_palette <- function(mhcclass = "MHC1") {
  palettes <- list(MHC1       = c("#fde725", "#440154"),
                   MHC1_mouse = c("#fde725", "#440154"),
                   MHC2       = c("#21918c", "#440154"))
  if (!is.null(mhcclass) && length(mhcclass) == 1 && mhcclass %in% names(palettes))
    palettes[[mhcclass]] else palettes$MHC1
}

#' Provider sentence of a report header
#'
#' The one-line attribution every report template prints under its description.
#' The organisation used to be hardcoded into each skeleton's opening paragraph,
#' which branded every rendered report of a distributable package to a single
#' platform; it is now the optional `Provider` report param, and this helper
#' turns that param into the sentence.
#'
#' An empty/unset `Provider` yields a neutral sentence naming no organisation,
#' so a report is never attributed to someone who did not produce it.
#'
#' @param provider Organisation or person that produced the report, as a single
#'   string. `""` (the param default), `NA` or `NULL` select the generic
#'   sentence.
#'
#' @return A single string, ready to be emitted from an inline `\\Sexpr`-style
#'   `` `r ...` `` expression in a report template.
#'
#' @export
#'
#' @examples
#' provider_line("Immunopeptidomics Platform (IPP)")
#' provider_line("")
provider_line <- function(provider = "") {
  generic <- "Generated with the HowMaHiCo R package."
  if (is.null(provider) || length(provider) == 0) return(generic)
  provider <- as.character(provider)[1]
  if (is.na(provider) || !nzchar(trimws(provider))) return(generic)
  paste0("Provided by ", trimws(provider), ".")
}

#' All pairwise Condition comparisons
#'
#' Replacement for the bare `combn(conditions, 2)` the report templates used to
#' call: [utils::combn()] errors with `n < m` when a subset happens to contain a
#' single Condition, which aborted the whole render. This returns an **empty
#' list** in that case, so the calling section can print a note and move on.
#'
#' @param conditions Character vector or factor of condition names (factor levels
#'   are used, so the report's annotation order is preserved).
#' @param self Include the self-comparisons (`A vs A`) appended after the pairs,
#'   as the overlap-matrix sections need. Default `FALSE`.
#'
#' @return A list of length-2 character vectors, named `"<Cond1>_vs_<Cond2>"`;
#'   empty (and, with `self = TRUE`, self-comparisons only) when fewer than two
#'   conditions are present.
#'
#' @export
#'
#' @examples
#' condition_pairs(c("CTRL", "TREAT", "OTHER"))
#' condition_pairs("CTRL")                 # empty list, no error
#' condition_pairs("CTRL", self = TRUE)    # just CTRL vs CTRL
condition_pairs <- function(conditions, self = FALSE) {
  conditions <- if (is.factor(conditions)) levels(droplevels(conditions))
                else unique(as.character(conditions))
  conditions <- conditions[!is.na(conditions)]

  pairs <- if (length(conditions) < 2) list()
           else utils::combn(conditions, 2, simplify = FALSE)
  if (self)
    pairs <- c(pairs, lapply(conditions, function(x) c(x, x)))

  if (length(pairs) == 0) return(pairs)
  names(pairs) <- vapply(pairs, function(x) paste0(x, collapse = "_vs_"), character(1))
  pairs
}
