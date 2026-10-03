#' Reference table of common peptide modifications
#'
#' The lookup table behind [translate_ptm()]: UniMod accession, readable name and
#' monoisotopic delta mass for the modifications seen in LC-immunopeptidomics
#' data. Rows are ordered **by how commonly the modification occurs**, because
#' delta-mass lookup takes the first row within tolerance and a few
#' modifications are mass-degenerate (`Glu->pyro-Glu` / `Dehydrated` both
#' -18.010565; `Gln->pyro-Glu` / `Ammonia-loss` both -17.026549). Pass a
#' reordered or extended copy to [translate_ptm()] to change that preference.
#'
#' @return A data frame with columns `accession` (integer UniMod accession),
#'   `name` (readable modification name) and `mono_mass` (monoisotopic delta
#'   mass in Da).
#'
#' @seealso [translate_ptm()], which consumes this table.
#'
#' @export
#'
#' @examples
#' head(ptm_reference())
#' subset(ptm_reference(), name == "Oxidation")
ptm_reference <- function() {
  data.frame(
    accession = c(35L, 4L, 1L, 7L, 21L, 28L, 27L, 5L, 34L, 36L, 37L,
                  425L, 345L, 26L, 122L, 2L, 121L, 30L, 312L, 23L, 385L),
    name = c("Oxidation", "Carbamidomethyl", "Acetyl", "Deamidated", "Phospho",
             "Gln->pyro-Glu", "Glu->pyro-Glu", "Carbamyl", "Methyl", "Dimethyl",
             "Trimethyl", "Dioxidation", "Trioxidation", "Pyro-carbamidomethyl",
             "Formyl", "Amidated", "GlyGly", "Cation:Na", "Cysteinyl",
             "Dehydrated", "Ammonia-loss"),
    mono_mass = c(15.994915, 57.021464, 42.010565, 0.984016, 79.966331,
                  -17.026549, -18.010565, 43.005814, 14.015650, 28.031300,
                  42.046950, 31.989829, 47.984744, 39.994915, 27.994915,
                  -0.984016, 114.042927, 21.981943, 119.004099,
                  -18.010565, -17.026549),
    stringsAsFactors = FALSE
  )
}

# Translate one PTM token. Returns the readable name, or the token unchanged when
# nothing matches, so an unknown modification is still visible on the heatmap
# instead of silently becoming NA.
.translate_ptm_one <- function(x, tol, reference) {
  if (is.na(x) || !nzchar(trimws(x))) return(x)

  # the payload is whatever sits inside () or [] -- "2M(15.9949)",
  # "(UniMod:35)", "[+15.99]" -- and the bare string when there is no bracket
  inner <- regmatches(x, regexpr("\\(([^()]*)\\)|\\[([^][]*)\\]", x))
  token <- if (length(inner) == 1L) gsub("^[(\\[]|[)\\]]$", "", inner) else x

  # DIA-NN: UniMod accession
  unimod <- regmatches(token, regexpr("(?i)unimod:?\\s*[0-9]+", token, perl = TRUE))
  if (length(unimod) == 1L) {
    acc <- as.integer(regmatches(unimod, regexpr("[0-9]+", unimod)))
    hit <- match(acc, reference$accession)
    if (!is.na(hit)) return(reference$name[hit])
    return(x)
  }

  # FragPipe (and bracketed PEAKS exports): signed delta mass. A token that is
  # already a name -- PEAKS' usual "Oxidation (M)" -- carries no number here and
  # falls through to be returned unchanged.
  num <- regmatches(token, regexpr("[-+]?[0-9]*\\.?[0-9]+", token))
  if (length(num) == 1L) {
    mass <- suppressWarnings(as.numeric(num))
    if (!is.na(mass)) {
      hit <- which(abs(reference$mono_mass - mass) <= tol)[1]
      if (!is.na(hit)) return(reference$name[hit])
    }
  }
  x
}

#' Translate PTM tokens into readable modification names
#'
#' The `PTM` column of `pep_all` is search-engine-specific:
#'
#' * **DIA-NN** writes UniMod accessions — `(UniMod:35)`
#' * **FragPipe** writes monoisotopic delta masses behind a position+residue
#'   prefix — `2M(15.9949)`
#' * **PEAKS** writes the modification *name* — `Oxidation (M)` — and carries the
#'   delta mass in the peptide string instead; bracketed delta masses
#'   (`[+15.99]`) still turn up in some exports
#'
#' This maps all of those onto one readable name, so PTM plots are comparable
#' across engines. Handling the delta-mass form matters because it is what the
#' project's default (FragPipe) data uses, and a token that is already a name
#' simply passes through unchanged.
#'
#' Display-time only — `pep_all$PTM` itself is left raw, following the same
#' "data keys unchanged" rule as the report's renamed display labels.
#'
#' Translation is name-only: the residue and position prefix (`2M` in
#' `2M(15.9949)`) is dropped, because the engines disagree on how they are
#' written, so equivalent modifications collapse onto a single plot row. A token
#' that matches nothing is returned **unchanged** rather than becoming `NA`.
#'
#' @param x Character vector of PTM tokens. The payload is taken from inside
#'   `()` or `[]` when present, else the whole string. `NA` and `""` pass
#'   through.
#' @param tol Delta-mass matching tolerance in Da. The default `0.01` is wide
#'   enough for 2-decimal rounding (`[+15.99]`) and still separates
#'   near-neighbours such as Acetyl (42.010565) from Trimethyl (42.046950).
#' @param reference Lookup table; defaults to [ptm_reference()]. The first row
#'   within `tol` wins, so row order encodes the preference between
#'   mass-degenerate modifications.
#'
#' @return A character vector the same length as `x`, with recognised tokens
#'   replaced by their modification name.
#'
#' @seealso [ptm_reference()] for the table, [plot_ptm_heatmap()] which applies
#'   this at plot time.
#'
#' @export
#'
#' @examples
#' translate_ptm(c("(UniMod:35)", "2M(15.9949)", "[+15.99]", "N-term(42.0106)"))
#' translate_ptm("(UniMod:9999)")   # unknown accession, returned unchanged
translate_ptm <- function(x, tol = 0.01, reference = ptm_reference()) {
  if (length(x) == 0L) return(character(0))
  x <- as.character(x)

  # PTM vectors carry a handful of distinct tokens over millions of rows, so
  # translate the unique set and map back
  u <- unique(x)
  translated <- vapply(u, .translate_ptm_one, character(1),
                       tol = tol, reference = reference, USE.NAMES = FALSE)
  translated[match(x, u)]
}
