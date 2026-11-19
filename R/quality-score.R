# Immunopeptidomics sample quality score
#
# Per-sample, interpretable signals -> 0-100 sub-scores via green/amber/red
# thresholds -> weighted composite. Inspired by the HowDirty contamination
# score, but inverted: this scores how strongly a sample resembles a real HLA
# immunopeptidome (goodness) rather than contaminant load (badness).
#
# Thresholds come from built-in literature defaults or from in-experiment QC
# samples (no external benchmark data, no extra package dependency). The
# non-tryptic signal is deliberately low-weight and QC-relative because some
# HLA-I alleles legitimately use K/R as a C-terminal anchor.

#' Per-position anchor information content of equal-length peptides
#'
#' Computes the Shannon information content (in bits) at one or more aligned
#' positions of a set of fixed-length peptide sequences, the quantity that
#' drives a sequence-logo's letter height. A sharp anchor (e.g. a single residue
#' dominating P2 or the C-terminus of HLA-I 9-mers) yields high information; a
#' flat, motif-less distribution yields ~0. This is the data-only basis for the
#' motif-clarity dimension of [score_sample_quality()] (no external binding
#' predictor or HLA typing needed) and reuses the same per-position frequency
#' idea as [ggseqlogo_bylength()].
#'
#' @param sequences Character vector of peptide sequences, all of the same
#'   length (shorter/longer entries and empty strings are dropped).
#' @param positions Integer vector of 1-based positions to score. Negative
#'   values count from the C-terminus (`-1` = last residue). Default
#'   `c(2, -1)` (the HLA-I P2 and PΩ anchors).
#' @param min_n Minimum number of usable sequences required; below this the
#'   estimate is too noisy and `NA` is returned. Default `10`.
#'
#' @return The summed information content (bits) over `positions`, or `NA_real_`
#'   when fewer than `min_n` equal-length sequences are available. The per-residue
#'   maximum is `log2(20)` bits, so the sum over two positions ranges `0`–`~8.6`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' anchor_information_content(c("SLFIGLKEV", "GLFDSLKEA", "ALWGFFPVL"))
#' }
anchor_information_content <- function(sequences, positions = c(2, -1), min_n = 10) {
  sequences <- as.character(sequences)
  sequences <- sequences[!is.na(sequences) & nzchar(sequences)]
  if (length(sequences) == 0) return(NA_real_)
  len <- stats::median(nchar(sequences))
  sequences <- sequences[nchar(sequences) == len]
  if (length(sequences) < min_n) return(NA_real_)

  # alphabet + negative-position handling shared with the pepchem engine, so the
  # two per-position frequency computations cannot drift apart
  aa <- .aa_alphabet()
  max_bits <- log2(length(aa))
  resolved <- .resolve_positions(positions, len)

  ic <- vapply(resolved, function(p) {
    if (p < 1 || p > len) return(NA_real_)
    residues <- substr(sequences, p, p)
    residues <- residues[residues %in% aa]
    if (length(residues) == 0) return(NA_real_)
    freq <- table(factor(residues, levels = aa)) / length(residues)
    freq <- freq[freq > 0]
    entropy <- -sum(freq * log2(freq))
    max_bits - entropy
  }, numeric(1))

  if (all(is.na(ic))) NA_real_ else sum(ic, na.rm = TRUE)
}

# Length range of the *other* MHC class that falls outside the current window,
# used by the cross-class co-enrichment metric and plot. MHC1 ligands are short
# (human 8-13, mouse 7-11), MHC2 long (12-25); contamination by the other class
# shows up as an excess of peptides in that other window beyond the current one.
# Returns c(lo, hi) (inclusive) or NULL when the class has no defined "other
# class" (a custom window), so the metric/plot are undefined. Windows come from
# mhc_length_window() so a new class is added in one place.
.cross_class_range <- function(mhcclass, shortpep_range = c(8, 13)) {
  if (!mhcclass %in% mhc_classes()) return(NULL)
  cur <- shortpep_range
  if (.is_mhc1(mhcclass)) {
    other_hi <- mhc_length_window("MHC2")[2]
    rng <- c(cur[2] + 1, other_hi)          # MHC2 contamination: above the MHC1 window
  } else {
    other_lo <- mhc_length_window("MHC1")[1]
    rng <- c(other_lo, cur[1] - 1)          # MHC1 contamination: below the MHC2 window
  }
  if (rng[1] > rng[2]) return(NULL)
  rng
}

# Is this an MHC-I class (human or mouse)? The 9-mer/anchor metrics are defined
# for both, with mouse scoring 8- AND 9-mers (H-2Kb favours 8-mers, H-2Db 9-mers).
.is_mhc1 <- function(mhcclass) isTRUE(mhcclass %in% c("MHC1", "MHC1_mouse"))

# Canonical ligand length(s) of an MHC-I class: 9 for human HLA-I, 8 and 9 for
# murine H-2.
.canonical_lengths <- function(mhcclass) if (identical(mhcclass, "MHC1_mouse")) c(8L, 9L) else 9L

# The most frequent of `candidates` in `lengths` (first candidate on a tie or
# when none is present), so anchor scoring always uses one aligned length set.
.modal_length <- function(lengths, candidates) {
  if (length(candidates) == 1) return(candidates)
  counts <- vapply(candidates, function(k) sum(lengths == k, na.rm = TRUE), numeric(1))
  candidates[which.max(counts)]
}

# Fraction of ligands that belong to a nested peptide family.
#
# The class-II counterpart of anchor_information_content(). MHC-II ligands are
# trimmed to ragged, length-variable sets around a shared ~9-residue binding
# core, so a genuine HLA-II immunopeptidome is dominated by nested families while
# a background/contaminant set is not. Unlike a motif model this needs no
# alignment and no register guess: a sequence counts as nested when ANY of its
# k-mers also occurs in another distinct sequence of the same sample.
#
# k is fixed at 9 because that is the length of the MHC-II binding core;
# sequences shorter than k cannot be assessed and are excluded from both the
# numerator and the denominator. NA for fewer than two assessable sequences.
.nested_core_fraction <- function(sequences, k = 9L) {
  seqs <- unique(as.character(sequences))
  seqs <- seqs[!is.na(seqs)]
  seqs <- seqs[nchar(seqs) >= k]
  n <- length(seqs)
  if (n < 2) return(NA_real_)

  # every k-mer of every sequence, tagged with the sequence it came from
  n_windows <- nchar(seqs) - k + 1L
  idx <- rep(seq_len(n), times = n_windows)
  starts <- unlist(lapply(n_windows, seq_len), use.names = FALSE)
  kmers <- substring(seqs[idx], starts, starts + k - 1L)

  # one (k-mer, sequence) pair at most, so an internal repeat cannot make a
  # sequence look shared with itself
  keep <- !duplicated(paste0(kmers, "
", idx))
  kmers <- kmers[keep]; idx <- idx[keep]

  tab <- table(kmers)
  shared <- kmers %in% names(tab)[tab > 1L]
  length(unique(idx[shared])) / n
}

# Median absolute difference between an observed and a predicted column, used
# for the DIA calibration-accuracy metrics. NA when either column is absent, or
# when every difference is 0 -- the same guard the dummy DIA-NN `ppm` gets, so a
# placeholder column cannot score as perfect accuracy.
.median_abs_delta <- function(observed, predicted) {
  if (is.null(observed) || is.null(predicted)) return(NA_real_)
  delta <- abs(suppressWarnings(as.numeric(observed) - as.numeric(predicted)))
  delta <- delta[is.finite(delta)]
  if (length(delta) == 0 || all(delta == 0)) return(NA_real_)
  stats::median(delta)
}

#' Raw per-sample immunopeptidomics quality metrics
#'
#' Computes, for each `Sample` in a `pep_all` table, the raw (un-scored) quality
#' signals consumed by [score_sample_quality()]. Every metric is derived from the
#' unified `pep_all` schema with no external data.
#'
#' @param pep_all A unified `pep_all` data frame (see the package's `pep_all`
#'   schema): one row per peptide-sample observation, with at least `Sample`,
#'   `Peptide`, `Sequence`, `Length`, `Cter`, `Charge`, `Accession` and
#'   (optionally) `ppm`.
#' @param shortpep_range Length-2 numeric `c(min, max)`: the biologically
#'   expected ligand-length window (e.g. `c(8, 13)` for HLA-I, `c(12, 25)` for
#'   HLA-II).
#' @param mhcclass `"MHC1"`, `"MHC1_mouse"` or `"MHC2"`. For `"MHC2"` the
#'   canonical-length and anchor-motif metrics are returned as `NA` (no
#'   fixed-length anchor model), so they drop out of the composite downstream —
#'   `frac_nested_core` is the class-II motif dimension instead, and
#'   [quality_thresholds_default()] gives it the anchor metric's weight there.
#'   For `"MHC1_mouse"`, `frac_9mer` counts 8- **and** 9-mers (both canonical for
#'   murine H-2) and the anchor motif is scored on whichever of the two the
#'   sample has more of.
#'
#' @return A data frame with one row per `Sample` and columns: `frac_in_window`,
#'   `frac_9mer`, `frac_cterm_KR`, `frac_cterm_KR_longonly`, `anchor_information`,
#'   `frac_nested_core`, `median_abs_rt_error`, `median_abs_im_error`,
#'   `frac_cross_class`, `frac_charge_1_2`, `n_unique_pep`,
#'   `n_unique_pep_in_window`, `n_source_proteins`, `median_abs_ppm`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' qc_metrics_by_sample(pep_all, shortpep_range = c(8, 13), mhcclass = "MHC1")
#' }
qc_metrics_by_sample <- function(pep_all, shortpep_range = c(8, 13), mhcclass = "MHC1") {
  is_mhc1 <- .is_mhc1(mhcclass)
  canonical_len <- .canonical_lengths(mhcclass)
  lo <- shortpep_range[1]; hi <- shortpep_range[2]
  cross_rng <- .cross_class_range(mhcclass, shortpep_range)
  has_ppm <- "ppm" %in% names(pep_all)

  samples <- if (is.factor(pep_all$Sample)) levels(pep_all$Sample) else unique(pep_all$Sample)
  samples <- samples[samples %in% unique(as.character(pep_all$Sample))]

  rows <- lapply(samples, function(s) {
    d <- pep_all[as.character(pep_all$Sample) == s, , drop = FALSE]
    pep <- d[!duplicated(d$Peptide), , drop = FALSE]   # one row per distinct peptide
    n_pep <- nrow(pep)
    if (n_pep == 0) {
      in_win <- out_win <- logical(0)
    } else {
      in_win <- pep$Length >= lo & pep$Length <= hi
      out_win <- !in_win
    }
    cter <- toupper(as.character(pep$Cter))
    kr <- cter %in% c("K", "R")

    # charge plausibility among in-window peptide observations
    short_obs <- get_charge_group(d[d$Length >= lo & d$Length <= hi, , drop = FALSE])
    frac_charge_1_2 <- if (nrow(short_obs) == 0) NA_real_ else
      mean(short_obs$Charge_group %in% c("+ 1", "+ 2"))

    # mass accuracy; DIA-NN reports ppm as a hardcoded dummy (all 0) -> NA
    if (has_ppm) {
      ppm <- d$ppm[!is.na(d$ppm)]
      median_abs_ppm <- if (length(ppm) == 0 || all(ppm == 0)) NA_real_ else
        stats::median(abs(ppm))
    } else {
      median_abs_ppm <- NA_real_
    }

    # DIA calibration accuracy: DIA-NN reports no observed precursor m/z (its
    # `ppm` is a dummy), but it does report a predicted RT and IM, and the
    # deviation from those is the DIA analogue of a mass error. NA -- and so
    # dropped from the composite -- for FragPipe/PEAKS, which carry no
    # prediction, exactly as `ppm` is dropped for DIA-NN.
    median_abs_rt_error <- .median_abs_delta(d[["RT"]], d[["Predicted.RT"]])
    median_abs_im_error <- .median_abs_delta(d[["invk0"]], d[["Predicted.IM"]])

    data.frame(
      Sample = s,
      frac_in_window = if (n_pep == 0) NA_real_ else mean(in_win),
      frac_9mer = if (!is_mhc1 || n_pep == 0) NA_real_ else mean(pep$Length %in% canonical_len),
      frac_cterm_KR = if (n_pep == 0) NA_real_ else mean(kr),
      frac_cterm_KR_longonly = if (sum(out_win) == 0) NA_real_ else mean(kr[out_win]),
      frac_cross_class = if (is.null(cross_rng) || n_pep == 0) NA_real_ else
        mean(pep$Length >= cross_rng[1] & pep$Length <= cross_rng[2]),
      # anchor_information_content() needs equal-length sequences, so for mouse
      # (two canonical lengths) it is computed on whichever of 8-/9-mers this
      # sample has more of, instead of silently dropping one of them.
      anchor_information = if (!is_mhc1) NA_real_ else
        anchor_information_content(pep$Sequence[pep$Length == .modal_length(pep$Length, canonical_len)]),
      # nested ragged families around a shared core: the class-II substitute
      # for anchor-motif clarity, computed on the in-window ligands only so a
      # long tryptic tail cannot manufacture nesting
      frac_nested_core = if (n_pep == 0) NA_real_ else
        .nested_core_fraction(pep$Sequence[in_win]),
      frac_charge_1_2 = frac_charge_1_2,
      n_unique_pep = n_pep,
      n_unique_pep_in_window = sum(in_win),
      n_source_proteins = dplyr::n_distinct(d$Accession),
      median_abs_ppm = median_abs_ppm,
      median_abs_rt_error = median_abs_rt_error,
      median_abs_im_error = median_abs_im_error,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out$Sample <- factor(out$Sample, levels = samples)
  out
}

#' Default quality-score thresholds and weights
#'
#' The literature-informed default scoring table used by [score_sample_quality()]
#' when no QC-relative calibration is requested. One row per metric, giving the
#' green (full-marks) and amber (half-marks) thresholds, the scoring `direction`,
#' the composite `weight`, and a human-readable `label`. Edit or pass a modified
#' copy to override. Metrics whose absolute thresholds are `NA` (the depth
#' metrics) are scored only in QC-relative mode (see
#' [calibrate_thresholds_from_qc()]).
#'
#' @param mhcclass MHC class the thresholds are for. `"MHC1_mouse"` relabels the
#'   `frac_9mer` row to "8/9-mer fraction" and raises its green/amber cut-offs,
#'   because that metric counts two canonical lengths for murine H-2. `"MHC2"`
#'   promotes `frac_nested_core` from a weight-0 diagnostic to the motif
#'   dimension (weight 3), since the anchor metric is undefined there.
#'
#' @return A data frame with columns `metric`, `label`, `direction`
#'   (`"higher_better"`/`"lower_better"`), `green`, `amber`, `weight`.
#'
#' @export
#'
#' @examples
#' quality_thresholds_default()
#' quality_thresholds_default("MHC1_mouse")
quality_thresholds_default <- function(mhcclass = "MHC1") {
  out <- data.frame(
    metric = c("frac_in_window", "frac_9mer", "frac_cterm_KR_longonly",
               "frac_cterm_KR", "anchor_information", "frac_nested_core",
               "frac_cross_class", "frac_charge_1_2", "n_unique_pep",
               "n_unique_pep_in_window", "n_source_proteins", "median_abs_ppm",
               "median_abs_rt_error", "median_abs_im_error"),
    label = c("Length in window", "9-mer fraction", "Tryptic background (long peptides)",
              "C-terminal K/R (diagnostic)", "Anchor motif clarity",
              "Nested cores (diagnostic)",
              "Cross-class contamination", "Charge 1+/2+",
              "Unique peptides", "Unique peptides in window", "Source proteins",
              "Median |ppm|", "Median |RT - predicted RT|",
              "Median |1/k0 - predicted 1/k0|"),
    direction = c("higher_better", "higher_better", "lower_better",
                  "lower_better", "higher_better", "higher_better",
                  "lower_better", "higher_better",
                  "higher_better", "higher_better", "higher_better",
                  "lower_better", "lower_better", "lower_better"),
    green = c(0.80, 0.35, 0.30, 0.30, 2.0, 0.25, 0.05, 0.85, NA, NA, NA, 5, 0.5, 0.010),
    amber = c(0.60, 0.20, 0.50, 0.50, 1.0, 0.10, 0.15, 0.70, NA, NA, NA, 10, 1.5, 0.030),
    weight = c(3, 1.5, 1, 0, 3, 0, 0.5, 1.5, 0.5, 0.5, 0.5, 1, 0.5, 0.5),
    stringsAsFactors = FALSE
  )

  # MHC-II has no fixed-length anchor model, so `anchor_information` is NA there
  # and `frac_nested_core` takes over the motif dimension at the same weight:
  # class-II ligands come as ragged, nested families around a shared 9-mer core,
  # which is exactly what that metric measures. For MHC-I it stays a weight-0
  # diagnostic (some nesting is normal, it is just not the primary signal).
  # The class-II cut-offs are provisional -- prefer ThresholdMode =
  # "qc_relative" when the experiment carries QC controls.
  if (identical(mhcclass, "MHC2")) {
    i <- match("frac_nested_core", out$metric)
    out$label[i]  <- "Nested-core families"
    out$green[i]  <- 0.50
    out$amber[i]  <- 0.30
    out$weight[i] <- 3
  }

  # Murine H-2 ligands peak at BOTH 8- and 9-mers, so `frac_9mer` counts two
  # lengths there (see qc_metrics_by_sample()); relabel it and raise the bar
  # accordingly - two canonical lengths out of a 5-length window are a higher
  # expectation than one out of six.
  if (identical(mhcclass, "MHC1_mouse")) {
    i <- match("frac_9mer", out$metric)
    out$label[i] <- "8/9-mer fraction"
    out$green[i] <- 0.50
    out$amber[i] <- 0.30
  }
  out
}

#' Map a raw metric value to a 0-100 quality sub-score
#'
#' Piecewise-linear scoring curve anchored on a green (full marks, 100) and amber
#' (half marks, 50) threshold, extrapolated linearly to a hard 0 floor an equal
#' step beyond amber, and clamped to `[0, 100]`. Returns `NA` when the value or
#' either threshold is `NA`, so undefined dimensions drop out of the composite
#' rather than scoring as 0.
#'
#' @param x Numeric raw metric value (may be `NA`).
#' @param green Threshold scoring 100.
#' @param amber Threshold scoring 50.
#' @param direction `"higher_better"` (larger is better) or `"lower_better"`.
#'
#' @return A numeric sub-score in `[0, 100]`, or `NA_real_`.
#'
#' @export
#'
#' @examples
#' score_curve(0.82, green = 0.80, amber = 0.60, direction = "higher_better")
#' score_curve(0.40, green = 5,    amber = 10,   direction = "lower_better")
score_curve <- function(x, green, amber, direction = c("higher_better", "lower_better")) {
  direction <- match.arg(direction)
  if (is.na(x) || is.na(green) || is.na(amber) || green == amber) return(NA_real_)
  if (direction == "higher_better") {
    red <- 2 * amber - green                 # lower bound (score 0)
    score <- 100 * (x - red) / (green - red)
  } else {
    red <- 2 * amber - green                 # upper bound (score 0)
    score <- 100 * (red - x) / (red - green)
  }
  max(0, min(100, score))
}

#' Derive QC-relative thresholds from tagged quality-control samples
#'
#' Replaces the absolute green/amber thresholds of a scoring table with values
#' anchored on the experiment's own QC sample(s): green is set to the QC median
#' of each metric and amber to that median relaxed by `slack` (downward for
#' `higher_better` metrics, upward for `lower_better`). This is what lets the
#' score be calibrated without any external benchmark dataset. Metrics whose QC
#' median is `NA` keep their default thresholds.
#'
#' @param metrics Output of [qc_metrics_by_sample()].
#' @param qc_samples Character vector of `Sample` values flagged as QC controls.
#' @param thresholds A scoring table to recalibrate (default
#'   [quality_thresholds_default()]); its `direction`/`weight`/`label` are kept.
#' @param slack Fractional tolerance for the amber band (default `0.2`, i.e. amber
#'   = green × 0.8 for higher-better, green × 1.2 for lower-better).
#'
#' @return The `thresholds` table with `green`/`amber` recomputed from the QC
#'   samples where possible.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' m <- qc_metrics_by_sample(pep_all, c(8, 13), "MHC1")
#' calibrate_thresholds_from_qc(m, qc_samples = c("QC_A", "QC_B"))
#' }
calibrate_thresholds_from_qc <- function(metrics, qc_samples,
                                         thresholds = quality_thresholds_default(),
                                         slack = 0.2) {
  qc <- metrics[as.character(metrics$Sample) %in% qc_samples, , drop = FALSE]
  if (nrow(qc) == 0)
    warning("No QC samples matched; keeping default thresholds.")
  for (i in seq_len(nrow(thresholds))) {
    m <- thresholds$metric[i]
    if (!m %in% names(qc)) next
    ref <- if (nrow(qc) == 0) NA_real_ else stats::median(qc[[m]], na.rm = TRUE)
    if (is.na(ref)) next
    thresholds$green[i] <- ref
    thresholds$amber[i] <- if (thresholds$direction[i] == "higher_better")
      ref * (1 - slack) else ref * (1 + slack)
  }
  thresholds
}

# Map a numeric 0-100 score to a traffic-light category.
.quality_category <- function(score) {
  factor(ifelse(is.na(score), NA_character_,
                ifelse(score >= 70, "Pass",
                       ifelse(score >= 40, "Warning", "Fail"))),
         levels = c("Pass", "Warning", "Fail"))
}

#' Score immunopeptidomics samples for overall quality
#'
#' Computes a per-sample composite quality score (and a traffic-light category)
#' from `pep_all`, combining several interpretable dimensions: length-window
#' fidelity, 9-mer dominance, anchor-motif clarity (nested-core families for
#' class II), non-tryptic specificity, charge plausibility, depth, and
#' mass/RT/ion-mobility accuracy. Each raw metric
#' ([qc_metrics_by_sample()]) is mapped to a 0-100 sub-score ([score_curve()])
#' against either built-in defaults ([quality_thresholds_default()]) or
#' thresholds calibrated from tagged QC samples ([calibrate_thresholds_from_qc()]).
#' The composite is the weighted mean of the *available* sub-scores, so
#' undefined dimensions (e.g. MHC-II anchors, DIA-NN `ppm`) drop out instead of
#' penalising the sample.
#'
#' @param pep_all A unified `pep_all` data frame.
#' @param shortpep_range Length-2 numeric `c(min, max)` ligand-length window.
#' @param mhcclass `"MHC1"`, `"MHC1_mouse"` (7-11 AA window, 8/9-mer canonical
#'   lengths) or `"MHC2"`; also selects the default threshold table.
#' @param qc_samples Optional character vector of `Sample` values flagged as QC
#'   controls (e.g. from an annotation `QC` column). Used to mark samples and,
#'   when `threshold_mode = "qc_relative"`, to calibrate thresholds.
#' @param threshold_mode `"default"` (absolute literature thresholds) or
#'   `"qc_relative"` (thresholds derived from `qc_samples`). `"qc_relative"`
#'   falls back to defaults if no QC samples are supplied.
#' @param thresholds Optional scoring table overriding the class-appropriate
#'   [quality_thresholds_default()] (which is used when this is `NULL`).
#' @param weights Optional named numeric vector overriding the `weight` column of
#'   `thresholds` (names = metric names).
#'
#' @return A data frame with one row per `Sample`: the raw metrics, a
#'   `score_<metric>` column per dimension, `composite_score`, `category`, and
#'   `is_QC`. Sorted by descending `composite_score`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' score_sample_quality(pep_all, c(8, 13), "MHC1")
#' score_sample_quality(pep_all, c(8, 13), "MHC1",
#'                      qc_samples = c("QC_A"), threshold_mode = "qc_relative")
#' }
score_sample_quality <- function(pep_all, shortpep_range = c(8, 13), mhcclass = "MHC1",
                                 qc_samples = NULL,
                                 threshold_mode = c("default", "qc_relative"),
                                 thresholds = NULL,
                                 weights = NULL) {
  threshold_mode <- match.arg(threshold_mode)
  if (is.null(thresholds)) thresholds <- quality_thresholds_default(mhcclass)
  if (!is.null(weights)) {
    idx <- match(names(weights), thresholds$metric)
    thresholds$weight[idx[!is.na(idx)]] <- weights[!is.na(idx)]
  }

  metrics <- qc_metrics_by_sample(pep_all, shortpep_range, mhcclass)

  if (threshold_mode == "qc_relative" && length(qc_samples) > 0) {
    thresholds <- calibrate_thresholds_from_qc(metrics, qc_samples, thresholds)
  }

  # 0-100 sub-score per metric
  score_cols <- list()
  for (i in seq_len(nrow(thresholds))) {
    m <- thresholds$metric[i]
    if (!m %in% names(metrics)) next
    score_cols[[paste0("score_", m)]] <- vapply(
      metrics[[m]],
      function(x) score_curve(x, thresholds$green[i], thresholds$amber[i],
                              thresholds$direction[i]),
      numeric(1))
  }
  scores <- as.data.frame(score_cols)

  # weighted composite over available (non-NA, positive-weight) sub-scores
  scored_metrics <- thresholds$metric[thresholds$weight > 0]
  w <- stats::setNames(thresholds$weight[thresholds$weight > 0], scored_metrics)
  sub <- as.matrix(scores[, paste0("score_", scored_metrics), drop = FALSE])
  composite <- vapply(seq_len(nrow(sub)), function(r) {
    vals <- sub[r, ]
    ok <- !is.na(vals)
    if (!any(ok)) return(NA_real_)
    stats::weighted.mean(vals[ok], w[ok])
  }, numeric(1))

  out <- cbind(metrics, scores)
  out$composite_score <- round(composite, 1)
  out$category <- .quality_category(out$composite_score)
  out$is_QC <- as.character(out$Sample) %in% qc_samples
  out <- out[order(-out$composite_score), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Read the QC-control samples from an annotation file
#'
#' Returns the `Sample` values that the annotation flags as experiment QC
#' controls in `qc_column` (`TRUE`, `T`, `1`, `QC`, `qc`, `yes` or `Yes`). This
#' is how `05_quality_score` and `09_overview` turn their `QCColumn` param into
#' the `qc_samples` of [score_sample_quality()]. A missing file, an unreadable
#' annotation, an empty `qc_column` or a column the annotation does not have all
#' give an empty vector, because QC tagging is optional.
#'
#' @param annotation_file Path to the annotation csv (read with [read_annot()]).
#' @param qc_column Name of the flag column (default `"QC"`).
#'
#' @return A character vector of QC `Sample` names (possibly empty).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' qc_samples_from_annotation("1_documentation/sample_annotation.csv", "QC")
#' }
qc_samples_from_annotation <- function(annotation_file, qc_column = "QC") {
  if (is.null(qc_column) || !nzchar(qc_column) || !file.exists(annotation_file))
    return(character(0))
  annot <- tryCatch(read_annot(annotation_file), error = function(e) NULL)
  if (is.null(annot) || !qc_column %in% names(annot)) return(character(0))
  is_qc <- as.character(annot[[qc_column]]) %in%
    c("TRUE", "T", "1", "QC", "qc", "yes", "Yes")
  unique(as.character(annot$Sample[is_qc]))
}

#' Plain-language red flags for the overview report
#'
#' Turns a [score_sample_quality()] table into a short list of problems worth a
#' biologist's attention, each with a severity and a sentence of detail. It
#' powers the "Red flags" section of `09_overview`. The rules are deliberately
#' few and transparent:
#'
#' * a sample whose composite score is **Fail** (< 40, `High`) or **Warning**
#'   (40-70, `Medium`);
#' * any **scored** quality dimension (weight > 0) whose sub-score falls below
#'   50, i.e. past its amber threshold. This is `High` when the sub-score is 0
#'   and `Medium` otherwise, and it covers cross-class contamination, tryptic
#'   background, length-window fidelity and the rest;
#' * a sample with fewer than `depth_ratio` times the experiment's median number
#'   of unique peptides (`Medium`). This is a relative test, so it needs at
#'   least two samples;
#' * with `pep_all`, a Condition with a single BioReplicate (`Low`), where
#'   replicate variability cannot be judged. `Sample` is `NA` for this
#'   experiment-level flag.
#'
#' @param scores Output of [score_sample_quality()].
#' @param thresholds The scoring table the scores were computed with (default
#'   [quality_thresholds_default()]); supplies the labels, weights and cut-offs.
#' @param depth_ratio Fraction of the median unique-peptide count below which a
#'   sample is flagged as shallow (default 0.5).
#' @param pep_all Optional `pep_all` table, used for the replicate check.
#'
#' @return A data frame with columns `Sample`, `Severity` (factor `High` >
#'   `Medium` > `Low`), `Flag` and `Detail`, ordered by severity. It has zero rows
#'   when nothing is flagged.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' scores <- score_sample_quality(pep_all, c(8, 13), "MHC1")
#' overview_red_flags(scores, pep_all = pep_all)
#' }
overview_red_flags <- function(scores, thresholds = quality_thresholds_default(),
                               depth_ratio = 0.5, pep_all = NULL) {
  flags <- list()
  add <- function(sample, severity, flag, detail) {
    flags[[length(flags) + 1]] <<- data.frame(Sample = sample, Severity = severity,
                                              Flag = flag, Detail = detail,
                                              stringsAsFactors = FALSE)
  }
  fmt <- function(x) format(signif(x, 3), trim = TRUE)
  samples <- as.character(scores$Sample)

  # 1. composite category
  for (i in seq_along(samples)) {
    cat_i <- as.character(scores$category[i])
    if (is.na(cat_i)) next
    if (cat_i == "Fail")
      add(samples[i], "High", "Low composite quality score",
          paste0("Composite score ", scores$composite_score[i],
                 " (below 40): this sample does not look like a typical immunopeptidome."))
    if (cat_i == "Warning")
      add(samples[i], "Medium", "Borderline composite quality score",
          paste0("Composite score ", scores$composite_score[i], " (between 40 and 70)."))
  }

  # 2. scored dimensions past their amber threshold
  scored <- thresholds[thresholds$weight > 0, , drop = FALSE]
  for (k in seq_len(nrow(scored))) {
    m <- scored$metric[k]
    sc <- scores[[paste0("score_", m)]]
    if (is.null(sc) || !m %in% names(scores)) next
    for (i in which(!is.na(sc) & sc < 50)) {
      add(samples[i], if (sc[i] == 0) "High" else "Medium", scored$label[k],
          paste0("Value ", fmt(scores[[m]][i]), " is past the amber threshold (",
                 fmt(scored$amber[k]), "; green ", fmt(scored$green[k]),
                 if (scored$direction[k] == "lower_better") ", lower is better" else
                   ", higher is better", ")."))
    }
  }

  # 3. relative depth
  if ("n_unique_pep" %in% names(scores) && sum(!is.na(scores$n_unique_pep)) >= 2) {
    med <- stats::median(scores$n_unique_pep, na.rm = TRUE)
    for (i in which(scores$n_unique_pep < depth_ratio * med)) {
      add(samples[i], "Medium", "Low identification depth",
          paste0(scores$n_unique_pep[i], " unique peptides, ",
                 round(100 * scores$n_unique_pep[i] / med), "% of the experiment median (",
                 fmt(med), ")."))
    }
  }

  # 4. Conditions without biological replication
  if (!is.null(pep_all) && all(c("Condition", "BioReplicate") %in% names(pep_all))) {
    n_rep <- tapply(as.character(pep_all$BioReplicate), as.character(pep_all$Condition),
                    function(x) length(unique(x)))
    for (cond in names(n_rep)[n_rep < 2]) {
      add(NA_character_, "Low", "Single biological replicate",
          paste0("Condition '", cond, "' has one BioReplicate, so replicate ",
                 "variability cannot be assessed."))
    }
  }

  out <- if (length(flags) == 0) {
    data.frame(Sample = character(0), Severity = character(0), Flag = character(0),
               Detail = character(0), stringsAsFactors = FALSE)
  } else {
    do.call(rbind, flags)
  }
  out$Severity <- factor(out$Severity, levels = c("High", "Medium", "Low"))
  sample_rank <- match(out$Sample, samples)
  out <- out[order(out$Severity, sample_rank, na.last = TRUE), , drop = FALSE]
  rownames(out) <- NULL
  out
}
