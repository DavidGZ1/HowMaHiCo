# Physicochemical properties of the peptide repertoire
#
# Describes the *chemistry* of the identified ligands rather than their identity
# (01/02), chromatography (03), quality (05) or abundance (06): amino-acid
# composition, per-position residue frequency, and per-peptide descriptors
# (GRAVY, pI, net charge, ...), compared between Conditions.
#
# Two design choices drive everything here.
#
# 1. Descriptors are sequence-intrinsic, so they are computed ONCE on the unique
#    sequences and joined back onto the peptide-sample rows. Running them per
#    observation would repeat the same computation for every replicate a peptide
#    was seen in.
#
# 2. The unit of analysis is the SAMPLE, not the peptide. Peptides within a
#    Condition are not independent replicates, so the primary comparison
#    summarises each sample first (median descriptor over its unique sequences,
#    residue frequency within that sample) and then tests across samples. The
#    peptide-level ("repertoire") track is kept as a descriptive effect size and
#    is explicitly flagged as pseudo-replicated in the report.
#
# `Peptides` (CRAN, Rcpp only) supplies the descriptor scales. It is vectorised
# and is the canonical implementation of GRAVY (mean Kyte-Doolittle), so the
# scales are not re-derived here. Peptides::aaComp() is NOT used: it returns a
# per-sequence list, and the amino-acid class fractions fall out of the
# composition matrix this file builds anyway.

# ---- internal helpers -------------------------------------------------------

# The canonical 20-residue alphabet, shared with anchor_information_content().
.aa_alphabet <- function()
  c("A", "R", "N", "D", "C", "Q", "E", "G", "H", "I",
    "L", "K", "M", "F", "P", "S", "T", "W", "Y", "V")

# 1-based positions, with negative values counting from the C-terminus
# (-1 = last residue). Either argument may be a vector, so both are recycled to
# the longer one first: ifelse() alone returns the length of its *test*, which
# silently collapses a scalar position resolved against a vector of lengths.
.resolve_positions <- function(positions, len) {
  n <- max(length(positions), length(len))
  positions <- rep_len(as.integer(positions), n)
  len <- rep_len(as.integer(len), n)
  ifelse(positions < 0, len + positions + 1L, positions)
}

# Display label of a position: "P1", "P2", ... or "P-1" for C-terminal offsets.
.position_label <- function(positions) paste0("P", positions)

# Amino-acid classes, following the same grouping Peptides::aaComp() reports.
.aa_classes <- function()
  list(Tiny      = c("A", "C", "G", "S", "T"),
       Small     = c("A", "C", "D", "G", "N", "P", "S", "T", "V"),
       Aliphatic = c("A", "I", "L", "V"),
       Aromatic  = c("F", "H", "W", "Y"),
       NonPolar  = c("A", "C", "F", "G", "I", "L", "M", "P", "V", "W", "Y"),
       Polar     = c("D", "E", "H", "K", "N", "Q", "R", "S", "T"),
       Charged   = c("D", "E", "H", "K", "R"),
       Basic     = c("H", "K", "R"),
       Acidic    = c("D", "E"))

# Keep the usable sequences: non-missing, non-empty, upper-cased.
.clean_sequences <- function(sequences) {
  s <- toupper(as.character(sequences))
  s[!is.na(s) & nzchar(s)]
}

# Per-sequence residue count matrix (sequences x 20). Non-standard residues
# (X, B, Z, U, and any modification character that slipped through) are dropped.
.residue_counts <- function(sequences) {
  aa <- .aa_alphabet()
  if (length(sequences) == 0)
    return(matrix(0L, nrow = 0, ncol = length(aa), dimnames = list(NULL, aa)))
  out <- t(vapply(strsplit(sequences, "", fixed = TRUE),
                  function(x) tabulate(match(x, aa), nbins = length(aa)),
                  integer(length(aa))))
  dimnames(out) <- list(NULL, aa)
  out
}

# Shared pairwise-comparison engine behind compare_pepchem() and
# compare_aa_frequency(): `dat` is long with a key column (the property or the
# residue), a numeric value and a Condition. Returns the pairwise table and
# carries the overall Kruskal-Wallis test in attr(, "kruskal").
.compare_groups <- function(dat, key, value, group = "Condition", fdr = 0.05,
                            min_n = 2) {
  empty <- data.frame(Key = character(0), Contrast = character(0),
                      Group1 = character(0), Group2 = character(0),
                      n1 = integer(0), n2 = integer(0),
                      Median1 = numeric(0), Median2 = numeric(0),
                      MedianDiff = numeric(0), CliffsDelta = numeric(0),
                      p_value = numeric(0), p_adj = numeric(0),
                      Significant = logical(0), stringsAsFactors = FALSE)
  empty_kw <- data.frame(Key = character(0), Statistic = numeric(0),
                         df = integer(0), p_value = numeric(0), p_adj = numeric(0),
                         stringsAsFactors = FALSE)
  names(empty)[1] <- key
  names(empty_kw)[1] <- key

  needed <- c(key, value, group)
  missing_cols <- setdiff(needed, names(dat))
  if (length(missing_cols) > 0)
    stop(".compare_groups(): missing column(s): ",
         paste(missing_cols, collapse = ", "), call. = FALSE)

  dat <- dat[!is.na(dat[[value]]), , drop = FALSE]
  pairs <- condition_pairs(dat[[group]])
  if (nrow(dat) == 0 || length(pairs) == 0) {
    attr(empty, "kruskal") <- empty_kw
    attr(empty, "fdr") <- fdr
    return(empty)
  }

  key_levels <- if (is.factor(dat[[key]])) levels(droplevels(dat[[key]]))
                else unique(as.character(dat[[key]]))
  keys <- as.character(dat[[key]])
  grp <- as.character(dat[[group]])

  # Kruskal-Wallis: one overall test per key.
  kw <- do.call(rbind, lapply(key_levels, function(k) {
    i <- keys == k
    v <- dat[[value]][i]; g <- grp[i]
    na_row <- data.frame(Key = k, Statistic = NA_real_, df = NA_integer_,
                         p_value = NA_real_, stringsAsFactors = FALSE)
    if (length(unique(g)) < 2 || length(v) < 3) return(na_row)
    tt <- try(stats::kruskal.test(v, factor(g)), silent = TRUE)
    if (inherits(tt, "try-error")) return(na_row)
    data.frame(Key = k, Statistic = unname(tt$statistic),
               df = as.integer(unname(tt$parameter)), p_value = tt$p.value,
               stringsAsFactors = FALSE)
  }))
  kw$p_adj <- stats::p.adjust(kw$p_value, method = "BH")
  names(kw)[1] <- key

  # Pairwise Wilcoxon rank-sum + effect sizes.
  out <- do.call(rbind, lapply(key_levels, function(k) {
    i <- keys == k
    v <- dat[[value]][i]; g <- grp[i]
    do.call(rbind, lapply(pairs, function(p) {
      x <- v[g == p[1]]; y <- v[g == p[2]]
      pv <- if (length(x) < min_n || length(y) < min_n) NA_real_ else {
        tt <- try(stats::wilcox.test(x, y, exact = FALSE), silent = TRUE)
        if (inherits(tt, "try-error")) NA_real_ else tt$p.value
      }
      m1 <- if (length(x)) stats::median(x) else NA_real_
      m2 <- if (length(y)) stats::median(y) else NA_real_
      data.frame(Key = k, Contrast = paste0(p[2], "_vs_", p[1]),
                 Group1 = p[1], Group2 = p[2],
                 n1 = length(x), n2 = length(y),
                 Median1 = m1, Median2 = m2, MedianDiff = m2 - m1,
                 CliffsDelta = cliffs_delta(y, x),
                 p_value = pv, stringsAsFactors = FALSE)
    }))
  }))

  # Correct within a contrast: the family is "all keys tested for this pair".
  out$p_adj <- NA_real_
  for (ctr in unique(out$Contrast)) {
    i <- out$Contrast == ctr
    out$p_adj[i] <- stats::p.adjust(out$p_value[i], method = "BH")
  }
  out$Significant <- !is.na(out$p_adj) & out$p_adj < fdr
  out$Key <- factor(out$Key, levels = key_levels)
  names(out)[1] <- key
  rownames(out) <- NULL

  attr(out, "kruskal") <- kw
  attr(out, "fdr") <- fdr
  out
}

#' Per-sequence physicochemical descriptors
#'
#' Computes the peptide-chemistry descriptors behind the `07_pepchem` report.
#' Duplicated sequences are computed once and returned once, so this is safe to
#' call with the whole `Sequence` column of a long `pep_all` table.
#'
#' `GRAVY` is the grand average of hydropathy, the mean Kyte-Doolittle value of
#' the residues (Kyte & Doolittle 1982) and the standard hydrophobicity summary
#' for a peptide — exactly what [Peptides::hydrophobicity()] returns with
#' `scale = "KyteDoolittle"`. `pI`, `Charge`, `Boman`, `HydrophobicMoment`,
#' `InstabilityIndex` and `AliphaticIndex` come from the corresponding
#' `Peptides` functions. The `frac_*` columns are the fraction of residues in
#' each amino-acid class (the classes [Peptides::aaComp()] reports), derived here
#' from the composition matrix rather than by calling `aaComp()`, which returns a
#' per-sequence list and does not vectorise.
#'
#' Non-standard residues (`X`, `B`, `Z`, `U`) are ignored by the composition and
#' the class fractions; the `Peptides` descriptors apply their own rules.
#'
#' @param sequences Character vector of peptide sequences (unmodified, one-letter
#'   code). `NA` and empty strings are dropped.
#' @param ph pH at which the net `Charge` is computed. Default `7.4`.
#'
#' @return A data frame with one row per **unique** sequence: `Sequence`,
#'   `Length`, `GRAVY`, `MW`, `pI`, `Charge`, `Boman`, `HydrophobicMoment`,
#'   `InstabilityIndex`, `AliphaticIndex` and one `frac_<class>` column per
#'   amino-acid class. Zero rows when no usable sequence is supplied.
#'
#' @export
#'
#' @examples
#' peptide_properties(c("SIINFEKL", "GILGFVFTL"))
peptide_properties <- function(sequences, ph = 7.4) {
  classes <- .aa_classes()
  cols <- c("Sequence", "Length", "GRAVY", "MW", "pI", "Charge", "Boman",
            "HydrophobicMoment", "InstabilityIndex", "AliphaticIndex",
            paste0("frac_", names(classes)))
  seqs <- unique(.clean_sequences(sequences))
  if (length(seqs) == 0) {
    empty <- stats::setNames(
      c(list(character(0)), rep(list(numeric(0)), length(cols) - 1)), cols)
    return(as.data.frame(empty, stringsAsFactors = FALSE))
  }

  counts <- .residue_counts(seqs)
  n_std <- rowSums(counts)
  frac <- lapply(classes, function(cl)
    ifelse(n_std > 0, rowSums(counts[, cl, drop = FALSE]) / n_std, NA_real_))
  names(frac) <- paste0("frac_", names(classes))

  # Every Peptides function warns once per non-standard residue, so a single
  # X-containing peptide would raise one warning per descriptor and a real
  # dataset would bury the report in them. Report the count once instead, and
  # suppress only the warnings raised inside this block.
  n_nonstandard <- sum(n_std < nchar(seqs))
  if (n_nonstandard > 0)
    warning("peptide_properties(): ", n_nonstandard, " of ", length(seqs),
            " sequences contain non-standard residues (X, B, Z, U or a stray ",
            "modification character). They are excluded from the composition ",
            "and the frac_* columns; the Peptides descriptors apply their own ",
            "rules and may be approximate for them.", call. = FALSE)

  out <- suppressWarnings(data.frame(
    Sequence          = seqs,
    Length            = nchar(seqs),
    GRAVY             = Peptides::hydrophobicity(seqs, scale = "KyteDoolittle"),
    MW                = Peptides::mw(seqs),
    pI                = Peptides::pI(seqs),
    Charge            = Peptides::charge(seqs, pH = ph),
    Boman             = Peptides::boman(seqs),
    HydrophobicMoment = Peptides::hmoment(seqs),
    InstabilityIndex  = Peptides::instaIndex(seqs),
    AliphaticIndex    = Peptides::aIndex(seqs),
    stringsAsFactors  = FALSE))
  out <- cbind(out, as.data.frame(frac, stringsAsFactors = FALSE))
  rownames(out) <- NULL
  out[, cols]
}

#' Descriptor columns of a property set
#'
#' The named subsets of [peptide_properties()] the `07_pepchem` report offers
#' through its `PropertySet` param, so the choice lives in the package rather
#' than in a hand-maintained list inside the template.
#'
#' `"core"` is the set a QC read-through needs — peptide length, hydrophobicity,
#' isoelectric point and net charge. `"extended"` adds the descriptors that need
#' more interpretation (mass, Boman index, hydrophobic moment, instability and
#' aliphatic indices) plus the amino-acid class fractions.
#'
#' @param set `"core"` or `"extended"`.
#'
#' @return A character vector of column names of [peptide_properties()].
#'
#' @export
#'
#' @examples
#' pepchem_properties("core")
#' pepchem_properties("extended")
pepchem_properties <- function(set = c("core", "extended")) {
  set <- match.arg(set)
  core <- c("Length", "GRAVY", "pI", "Charge")
  if (set == "core") return(core)
  c(core, "MW", "Boman", "HydrophobicMoment", "InstabilityIndex", "AliphaticIndex",
    paste0("frac_", names(.aa_classes())))
}

#' Position-independent amino-acid composition
#'
#' Residue counts and frequencies over a set of sequences, optionally split by a
#' grouping vector (Condition, Sample, ...). Non-standard residues are dropped,
#' so the frequencies of the 20 standard residues sum to 1 within each group.
#'
#' @param sequences Character vector of peptide sequences.
#' @param groups Optional grouping vector, the same length as `sequences`
#'   (factor levels are preserved). `NULL` (default) puts everything in one group
#'   called `"all"`.
#' @param normalize Add the within-group `Frequency` column. Default `TRUE`.
#'
#' @return A long data frame with `Group`, `AA` (a factor over the 20 standard
#'   residues, in the canonical order), `Count`, `n_Sequences` and — when
#'   `normalize` is `TRUE` — `Frequency`.
#'
#' @export
#'
#' @examples
#' aa_composition(c("SIINFEKL", "GILGFVFTL"), groups = c("A", "B"))
aa_composition <- function(sequences, groups = NULL, normalize = TRUE) {
  aa <- .aa_alphabet()
  seqs <- toupper(as.character(sequences))
  grp <- if (is.null(groups)) rep("all", length(seqs)) else groups
  if (length(grp) != length(seqs))
    stop("aa_composition(): `groups` must be the same length as `sequences`.",
         call. = FALSE)

  keep <- !is.na(seqs) & nzchar(seqs)
  seqs <- seqs[keep]
  grp_levels <- if (is.factor(grp)) levels(droplevels(grp[keep]))
                else unique(as.character(grp[keep]))
  grp <- as.character(grp[keep])

  out <- data.frame(Group = character(0), AA = character(0), Count = integer(0),
                    n_Sequences = integer(0), stringsAsFactors = FALSE)
  if (length(seqs) > 0) {
    counts <- .residue_counts(seqs)
    out <- do.call(rbind, lapply(grp_levels, function(g) {
      i <- grp == g
      data.frame(Group = g, AA = aa,
                 Count = as.integer(colSums(counts[i, , drop = FALSE])),
                 n_Sequences = sum(i), stringsAsFactors = FALSE)
    }))
  }
  out$Group <- factor(out$Group, levels = grp_levels)
  out$AA <- factor(out$AA, levels = aa)
  if (normalize) {
    tot <- stats::ave(out$Count, out$Group, FUN = sum)
    out$Frequency <- ifelse(tot > 0, out$Count / tot, NA_real_)
  }
  rownames(out) <- NULL
  out
}

#' Per-position amino-acid frequency
#'
#' The position x residue frequency table a sequence logo draws, returned as data
#' instead of a plot — the numeric complement to [ggseqlogo_bylength()] and the
#' generalisation of [anchor_information_content()], which collapses this same
#' table to Shannon bits.
#'
#' Two modes:
#'
#' * `length` given (or both `length` and `positions` `NULL`, which picks the
#'   modal length): only peptides of that length are used and every position
#'   `1..length` is profiled. This is the mode for an anchor-motif heatmap.
#' * `positions` given with `length = NULL`: peptides of **all** lengths are used
#'   and each position is resolved against that peptide's own length, so
#'   `c(1, 2, -2, -1)` profiles the two N-terminal and two C-terminal residues
#'   across a mixed-length set.
#'
#' Negative positions count from the C-terminus (`-1` is the last residue).
#'
#' @param sequences Character vector of peptide sequences.
#' @param length Peptide length to restrict to, or `NULL` (default) for the modal
#'   length when `positions` is also `NULL`, and for "all lengths" when
#'   `positions` is given.
#' @param positions Integer vector of positions to profile, or `NULL` (default)
#'   for all positions of the fixed `length`.
#' @param groups Optional grouping vector, the same length as `sequences`.
#' @param min_n Minimum number of usable sequences per group; a group below this
#'   is dropped, since its frequencies would be noise. Default `10`.
#'
#' @return A long data frame with `Group`, `Position` (integer, as supplied, so
#'   negatives are preserved), `PositionLabel` (an ordered factor), `AA`,
#'   `Count`, `n_Sequences` and `Frequency`. Zero rows when nothing is usable.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' aa_position_frequency(pep_short$Sequence, groups = pep_short$Condition)
#' aa_position_frequency(pep_short$Sequence, positions = c(1, 2, -2, -1))
#' }
aa_position_frequency <- function(sequences, length = NULL, positions = NULL,
                                  groups = NULL, min_n = 10) {
  aa <- .aa_alphabet()
  empty <- data.frame(Group = character(0), Position = integer(0),
                      PositionLabel = character(0), AA = character(0),
                      Count = integer(0), n_Sequences = integer(0),
                      Frequency = numeric(0), stringsAsFactors = FALSE)

  seqs <- toupper(as.character(sequences))
  grp <- if (is.null(groups)) rep("all", base::length(seqs)) else groups
  if (base::length(grp) != base::length(seqs))
    stop("aa_position_frequency(): `groups` must be the same length as `sequences`.",
         call. = FALSE)

  keep <- !is.na(seqs) & nzchar(seqs)
  seqs <- seqs[keep]
  grp_levels <- if (is.factor(grp)) levels(droplevels(grp[keep]))
                else unique(as.character(grp[keep]))
  grp <- as.character(grp[keep])
  if (base::length(seqs) == 0) return(empty)

  lens <- nchar(seqs)
  if (is.null(length) && is.null(positions))
    length <- .modal_length(lens, sort(unique(lens)))
  if (!is.null(length)) {
    i <- lens == length
    seqs <- seqs[i]; grp <- grp[i]; lens <- lens[i]
    if (base::length(seqs) == 0) return(empty)
    if (is.null(positions)) positions <- seq_len(length)
  }
  positions <- as.integer(positions)

  out <- do.call(rbind, lapply(grp_levels, function(g) {
    i <- grp == g
    s <- seqs[i]; l <- lens[i]
    if (base::length(s) < min_n) return(NULL)
    do.call(rbind, lapply(positions, function(p) {
      idx <- .resolve_positions(p, l)
      ok <- idx >= 1 & idx <= l
      res <- substr(s[ok], idx[ok], idx[ok])
      res <- res[res %in% aa]
      if (base::length(res) == 0) return(NULL)
      tab <- tabulate(match(res, aa), nbins = base::length(aa))
      data.frame(Group = g, Position = p, PositionLabel = .position_label(p),
                 AA = aa, Count = as.integer(tab),
                 n_Sequences = base::length(res),
                 Frequency = tab / base::length(res), stringsAsFactors = FALSE)
    }))
  }))
  if (is.null(out)) return(empty)

  out$Group <- factor(out$Group, levels = grp_levels)
  out$AA <- factor(out$AA, levels = aa)
  out$PositionLabel <- factor(out$PositionLabel,
                              levels = .position_label(positions))
  rownames(out) <- NULL
  attr(out, "length") <- length
  out
}

#' Per-sample peptide physicochemical descriptors
#'
#' Entry point of the `07_pepchem` engine. Reduces a long `pep_all`-shaped table
#' to its distinct `Sequence` per `Sample` — the properties are
#' sequence-intrinsic, so counting every PSM would weight them by how often a
#' peptide happened to be re-sequenced — and joins on [peptide_properties()],
#' computed once over the unique sequences of the whole table.
#'
#' @param input A `pep_all`-shaped data frame; needs `Sequence` and `Sample`, and
#'   carries `Condition`/`BioReplicate` through when present.
#' @param ph pH for the net-charge descriptor, passed to [peptide_properties()].
#'
#' @return A data frame with one row per (`Sample`, `Sequence`) pair: the
#'   annotation columns, `Sequence`, and every descriptor column of
#'   [peptide_properties()].
#'
#' @export
#'
#' @examples
#' \dontrun{
#' props <- pepchem_by_sample(pep_short)
#' }
pepchem_by_sample <- function(input, ph = 7.4) {
  needed <- c("Sequence", "Sample")
  missing_cols <- setdiff(needed, names(input))
  if (length(missing_cols) > 0)
    stop("pepchem_by_sample(): missing column(s) in `input`: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)

  annot <- intersect(c("Sample", "BioReplicate", "Condition"), names(input))
  dat <- input |>
    dplyr::select(dplyr::all_of(c(annot, "Sequence"))) |>
    dplyr::filter(!is.na(.data$Sequence), nzchar(as.character(.data$Sequence))) |>
    dplyr::distinct() |>
    as.data.frame()
  dat$Sequence <- toupper(as.character(dat$Sequence))

  props <- peptide_properties(dat$Sequence, ph = ph)
  out <- dplyr::left_join(dat, props, by = "Sequence")
  rownames(out) <- NULL
  out
}

#' Summarise peptide descriptors within a group
#'
#' Collapses the per-peptide table of [pepchem_by_sample()] to one row per
#' (group, descriptor): the count, mean, median and sd over that group's unique
#' sequences. With the default `by = "Sample"` this is the first of the two
#' aggregation steps the report uses — [aggregate_pepchem()] is the second.
#'
#' @param props Output of [pepchem_by_sample()].
#' @param by Grouping column. Default `"Sample"`.
#' @param properties Descriptor columns to summarise. `NULL` (default) uses every
#'   numeric column that is not an annotation column.
#'
#' @return A long data frame with the `by` column, `Condition` (when present),
#'   `Property`, `N`, `Mean`, `Median` and `SD`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' summarise_pepchem(pepchem_by_sample(pep_short))
#' }
summarise_pepchem <- function(props, by = "Sample", properties = NULL) {
  if (!by %in% names(props))
    stop("summarise_pepchem(): `props` has no column '", by, "'.", call. = FALSE)

  annot <- c("Sample", "BioReplicate", "Condition", "Sequence")
  if (is.null(properties))
    properties <- names(props)[!names(props) %in% annot &
                                 vapply(props, is.numeric, logical(1))]
  properties <- intersect(properties, names(props))
  if (length(properties) == 0)
    stop("summarise_pepchem(): no numeric descriptor column found in `props`.",
         call. = FALSE)

  keys <- unique(c(by, intersect("Condition", names(props))))
  props |>
    dplyr::select(dplyr::all_of(c(keys, properties))) |>
    tidyr::pivot_longer(dplyr::all_of(properties), names_to = "Property",
                        values_to = "Value") |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(keys, "Property")))) |>
    dplyr::summarise(
      N      = sum(!is.na(.data$Value)),
      Mean   = .mean_na(.data$Value),
      Median = if (all(is.na(.data$Value))) NA_real_
               else stats::median(.data$Value, na.rm = TRUE),
      SD     = if (sum(!is.na(.data$Value)) < 2) NA_real_
               else stats::sd(.data$Value, na.rm = TRUE),
      .groups = "drop") |>
    dplyr::mutate(Property = factor(.data$Property, levels = properties)) |>
    as.data.frame()
}

#' Aggregate per-sample descriptor summaries to Conditions
#'
#' The second aggregation step: takes the per-sample table of
#' [summarise_pepchem()] and reports, for each Condition and descriptor, the mean
#' +/- sd **across samples** of the chosen per-sample statistic. This is the
#' replicate-respecting summary [plot_property_sample_summary()] draws — its
#' spread is between-sample variability, not between-peptide spread.
#'
#' @param sample_summary Output of [summarise_pepchem()] with `by = "Sample"`.
#' @param stat Per-sample statistic to aggregate: `"Median"` (default) or
#'   `"Mean"`.
#'
#' @return A data frame with `Condition`, `Property`, `n_Samples`, `Mean`, `SD`
#'   and `SEM`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' aggregate_pepchem(summarise_pepchem(pepchem_by_sample(pep_short)))
#' }
aggregate_pepchem <- function(sample_summary, stat = c("Median", "Mean")) {
  stat <- match.arg(stat)
  needed <- c("Condition", "Property", stat)
  missing_cols <- setdiff(needed, names(sample_summary))
  if (length(missing_cols) > 0)
    stop("aggregate_pepchem(): missing column(s): ",
         paste(missing_cols, collapse = ", "), call. = FALSE)

  sample_summary |>
    dplyr::rename(Value = dplyr::all_of(stat)) |>
    dplyr::group_by(.data$Condition, .data$Property) |>
    dplyr::summarise(
      n_Samples = sum(!is.na(.data$Value)),
      Mean      = .mean_na(.data$Value),
      SD        = if (sum(!is.na(.data$Value)) < 2) NA_real_
                  else stats::sd(.data$Value, na.rm = TRUE),
      .groups = "drop") |>
    dplyr::mutate(SEM = ifelse(.data$n_Samples > 0,
                               .data$SD / sqrt(.data$n_Samples), NA_real_)) |>
    as.data.frame()
}

#' Cliff's delta effect size
#'
#' The non-parametric effect size that pairs with a Wilcoxon rank-sum test: the
#' probability that a random value of `x` exceeds a random value of `y`, minus
#' the reverse. `0` means the distributions overlap completely, `+1`/`-1` that
#' they are fully separated. Unlike a difference of medians it is scale-free, so
#' descriptors on different units can be compared on one axis.
#'
#' Computed from the rank sum (ties contribute 0.5), so it is O(n log n) rather
#' than the O(n*m) pairwise definition.
#'
#' @param x,y Numeric vectors. `NA`s are dropped.
#'
#' @return A single number in `[-1, 1]`, or `NA_real_` when either vector is
#'   empty after dropping `NA`s.
#'
#' @export
#'
#' @examples
#' cliffs_delta(1:10, 1:10)
#' cliffs_delta(11:20, 1:10)
cliffs_delta <- function(x, y) {
  x <- x[!is.na(x)]; y <- y[!is.na(y)]
  n <- length(x); m <- length(y)
  if (n == 0 || m == 0) return(NA_real_)
  r <- rank(c(x, y))
  u <- sum(r[seq_len(n)]) - n * (n + 1) / 2
  2 * u / (n * m) - 1
}

#' Compare peptide descriptors between Conditions
#'
#' Kruskal-Wallis across all Conditions plus a pairwise Wilcoxon rank-sum test
#' for every Condition pair, BH-corrected within each contrast, with the median
#' difference and [cliffs_delta()] as effect sizes.
#'
#' `level` selects the unit of analysis, and the two tracks are **not**
#' interchangeable:
#'
#' * `"sample"` (default) summarises each sample first (median descriptor over
#'   its unique sequences) and tests across samples. Samples are the real
#'   replicates, so this is the honest test — but it is low-powered: with three
#'   replicates per Condition a two-sided Wilcoxon cannot go below p = 0.1, so
#'   read the effect sizes, not only the p-values.
#' * `"peptide"` pools the unique sequences of a Condition and tests across
#'   peptides. Peptides from one sample are not independent, so this track is
#'   pseudo-replicated: its p-values are anti-conservative and it should be read
#'   as a *description* of the repertoire difference (through Cliff's delta),
#'   not as inference.
#'
#' @param props Output of [pepchem_by_sample()].
#' @param level `"sample"` (default) or `"peptide"` — see above.
#' @param properties Descriptor columns to test. `NULL` (default) uses every
#'   numeric non-annotation column.
#' @param fdr Significance cut-off applied to the BH-adjusted p-values. Default
#'   `0.05`.
#'
#' @return A data frame with `Property`, `Level`, `Contrast`, `Group1`, `Group2`,
#'   `n1`, `n2`, `Median1`, `Median2`, `MedianDiff`, `CliffsDelta`, `p_value`,
#'   `p_adj` and `Significant`; the overall Kruskal-Wallis table is attached as
#'   `attr(, "kruskal")`. Zero rows when fewer than two Conditions are present.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' compare_pepchem(pepchem_by_sample(pep_short), level = "sample")
#' }
compare_pepchem <- function(props, level = c("sample", "peptide"),
                            properties = NULL, fdr = 0.05) {
  level <- match.arg(level)
  if (!"Condition" %in% names(props))
    stop("compare_pepchem(): `props` has no 'Condition' column.", call. = FALSE)

  annot <- c("Sample", "BioReplicate", "Condition", "Sequence")
  if (is.null(properties))
    properties <- names(props)[!names(props) %in% annot &
                                 vapply(props, is.numeric, logical(1))]
  properties <- intersect(properties, names(props))

  dat <- if (level == "sample") {
    summarise_pepchem(props, by = "Sample", properties = properties) |>
      dplyr::select(dplyr::all_of(c("Condition", "Property")), Value = "Median")
  } else {
    props |>
      dplyr::select(dplyr::all_of(c("Condition", properties))) |>
      tidyr::pivot_longer(dplyr::all_of(properties), names_to = "Property",
                          values_to = "Value") |>
      as.data.frame()
  }
  dat$Property <- factor(as.character(dat$Property), levels = properties)

  out <- .compare_groups(dat, key = "Property", value = "Value", fdr = fdr,
                         min_n = if (level == "sample") 2 else 3)
  kw <- attr(out, "kruskal")
  if (!is.null(kw) && nrow(kw) > 0) kw$Level <- level
  out <- cbind(out[1], Level = rep(level, nrow(out)), out[-1])
  attr(out, "kruskal") <- kw
  attr(out, "fdr") <- fdr
  out
}

#' Compare amino-acid frequencies between Conditions
#'
#' The composition counterpart of [compare_pepchem()]: each residue's frequency
#' is computed **within each sample** (over that sample's unique sequences), then
#' compared across Conditions with the same Kruskal-Wallis + pairwise Wilcoxon +
#' BH machinery. Testing per-sample frequencies rather than pooled residue counts
#' avoids treating the hundreds of thousands of residues in a Condition as
#' independent observations, which a chi-square on pooled counts would do.
#'
#' @param props Output of [pepchem_by_sample()]; needs `Sequence`, `Sample` and
#'   `Condition`.
#' @param fdr Significance cut-off on the BH-adjusted p-values. Default `0.05`.
#'
#' @return A data frame shaped like [compare_pepchem()]'s but keyed by `AA`, with
#'   an extra `Log2Ratio` column (log2 of the median frequency ratio,
#'   `Group2 / Group1`). The Kruskal-Wallis table is attached as
#'   `attr(, "kruskal")`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' compare_aa_frequency(pepchem_by_sample(pep_short))
#' }
compare_aa_frequency <- function(props, fdr = 0.05) {
  needed <- c("Sequence", "Sample", "Condition")
  missing_cols <- setdiff(needed, names(props))
  if (length(missing_cols) > 0)
    stop("compare_aa_frequency(): missing column(s) in `props`: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)

  comp <- aa_composition(props$Sequence, groups = props$Sample)
  key <- unique(props[, c("Sample", "Condition")])
  dat <- data.frame(
    AA = comp$AA,
    Condition = key$Condition[match(as.character(comp$Group),
                                    as.character(key$Sample))],
    Value = comp$Frequency, stringsAsFactors = FALSE)

  out <- .compare_groups(dat, key = "AA", value = "Value", fdr = fdr, min_n = 2)
  out$Log2Ratio <- log2(out$Median2 / out$Median1)
  out
}
