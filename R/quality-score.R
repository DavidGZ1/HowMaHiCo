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

  aa <- c("A", "R", "N", "D", "C", "Q", "E", "G", "H", "I",
          "L", "K", "M", "F", "P", "S", "T", "W", "Y", "V")
  max_bits <- log2(length(aa))
  resolved <- ifelse(positions < 0, len + positions + 1L, positions)

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
# (8-13), MHC2 long (12-25); contamination by the other class shows up as an
# excess of peptides in that other window beyond the current one. Returns
# c(lo, hi) (inclusive) or NULL when the class is not MHC1/MHC2 (no defined
# "other class", so the metric/plot are undefined).
.cross_class_range <- function(mhcclass, shortpep_range = c(8, 13)) {
  windows <- list(MHC1 = c(8L, 13L), MHC2 = c(12L, 25L))
  if (!mhcclass %in% names(windows)) return(NULL)
  cur <- shortpep_range
  if (mhcclass == "MHC1") {
    other_hi <- windows$MHC2[2]
    rng <- c(cur[2] + 1, other_hi)          # MHC2 contamination: above the MHC1 window
  } else {
    other_lo <- windows$MHC1[1]
    rng <- c(other_lo, cur[1] - 1)          # MHC1 contamination: below the MHC2 window
  }
  if (rng[1] > rng[2]) return(NULL)
  rng
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
#' @param mhcclass `"MHC1"` or `"MHC2"`. For `"MHC2"` the 9-mer and anchor-motif
#'   metrics are returned as `NA` (no fixed-length anchor model), so they drop
#'   out of the composite downstream.
#'
#' @return A data frame with one row per `Sample` and columns: `frac_in_window`,
#'   `frac_9mer`, `frac_cterm_KR`, `frac_cterm_KR_longonly`, `anchor_information`,
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
  is_mhc1 <- identical(mhcclass, "MHC1")
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

    data.frame(
      Sample = s,
      frac_in_window = if (n_pep == 0) NA_real_ else mean(in_win),
      frac_9mer = if (!is_mhc1 || n_pep == 0) NA_real_ else mean(pep$Length == 9),
      frac_cterm_KR = if (n_pep == 0) NA_real_ else mean(kr),
      frac_cterm_KR_longonly = if (sum(out_win) == 0) NA_real_ else mean(kr[out_win]),
      frac_cross_class = if (is.null(cross_rng) || n_pep == 0) NA_real_ else
        mean(pep$Length >= cross_rng[1] & pep$Length <= cross_rng[2]),
      anchor_information = if (!is_mhc1) NA_real_ else
        anchor_information_content(pep$Sequence[pep$Length == 9]),
      frac_charge_1_2 = frac_charge_1_2,
      n_unique_pep = n_pep,
      n_unique_pep_in_window = sum(in_win),
      n_source_proteins = dplyr::n_distinct(d$Accession),
      median_abs_ppm = median_abs_ppm,
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
#' @return A data frame with columns `metric`, `label`, `direction`
#'   (`"higher_better"`/`"lower_better"`), `green`, `amber`, `weight`.
#'
#' @export
#'
#' @examples
#' quality_thresholds_default()
quality_thresholds_default <- function() {
  data.frame(
    metric = c("frac_in_window", "frac_9mer", "frac_cterm_KR_longonly",
               "frac_cterm_KR", "anchor_information", "frac_cross_class",
               "frac_charge_1_2", "n_unique_pep", "n_unique_pep_in_window",
               "n_source_proteins", "median_abs_ppm"),
    label = c("Length in window", "9-mer fraction", "Tryptic background (long peptides)",
              "C-terminal K/R (diagnostic)", "Anchor motif clarity",
              "Cross-class contamination", "Charge 1+/2+",
              "Unique peptides", "Unique peptides in window", "Source proteins",
              "Median |ppm|"),
    direction = c("higher_better", "higher_better", "lower_better",
                  "lower_better", "higher_better", "lower_better", "higher_better",
                  "higher_better", "higher_better", "higher_better",
                  "lower_better"),
    green = c(0.80, 0.35, 0.30, 0.30, 2.0, 0.05, 0.85, NA, NA, NA, 5),
    amber = c(0.60, 0.20, 0.50, 0.50, 1.0, 0.15, 0.70, NA, NA, NA, 10),
    weight = c(3, 1.5, 1, 0, 3, 0.5, 1.5, 0.5, 0.5, 0.5, 1),
    stringsAsFactors = FALSE
  )
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
#' fidelity, 9-mer dominance, anchor-motif clarity, non-tryptic specificity,
#' charge plausibility, depth, and mass accuracy. Each raw metric
#' ([qc_metrics_by_sample()]) is mapped to a 0-100 sub-score ([score_curve()])
#' against either built-in defaults ([quality_thresholds_default()]) or
#' thresholds calibrated from tagged QC samples ([calibrate_thresholds_from_qc()]).
#' The composite is the weighted mean of the *available* sub-scores, so
#' undefined dimensions (e.g. MHC-II anchors, DIA-NN `ppm`) drop out instead of
#' penalising the sample.
#'
#' @param pep_all A unified `pep_all` data frame.
#' @param shortpep_range Length-2 numeric `c(min, max)` ligand-length window.
#' @param mhcclass `"MHC1"` or `"MHC2"`.
#' @param qc_samples Optional character vector of `Sample` values flagged as QC
#'   controls (e.g. from an annotation `QC` column). Used to mark samples and,
#'   when `threshold_mode = "qc_relative"`, to calibrate thresholds.
#' @param threshold_mode `"default"` (absolute literature thresholds) or
#'   `"qc_relative"` (thresholds derived from `qc_samples`). `"qc_relative"`
#'   falls back to defaults if no QC samples are supplied.
#' @param thresholds Optional scoring table overriding
#'   [quality_thresholds_default()].
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
                                 thresholds = quality_thresholds_default(),
                                 weights = NULL) {
  threshold_mode <- match.arg(threshold_mode)
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
