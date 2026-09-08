# Advanced quantitative statistics for immunopeptidomics
#
# Turns the long `pep_all` table into a feature x unit log2(Area) matrix, then
# runs the differential-abundance workflow behind the 06_quant_stats report:
# filtering -> between-sample normalization -> (optional) left-censored
# imputation -> moderated-t (limma) or ordinary Welch t testing per condition
# pair, complemented by a presence/absence (Fisher exact) track for the
# condition-exclusive ligands that a quantitative test cannot rank.
#
# limma lives in Suggests, not Imports: it is a Bioconductor package and most
# HowMaHiCo runs (QC reports) never need it. Every entry point that requires it
# goes through .require_limma(), and `method = "ttest"` is a dependency-free
# fallback that follows the same code path otherwise.

# ---- internal helpers -------------------------------------------------------

# Sum on the linear scale, but keep an all-missing group missing (sum(na.rm)
# would turn it into 0, and log2(0) into -Inf).
.sum_na <- function(x) if (all(is.na(x))) NA_real_ else sum(x, na.rm = TRUE)
.mean_na <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)

.require_limma <- function() {
  if (!requireNamespace("limma", quietly = TRUE))
    stop("This step needs the 'limma' package (Bioconductor), which is not installed.\n",
         "  Install it with: BiocManager::install(\"limma\")\n",
         "  Or use the dependency-free fallback: StatMethod = \"ttest\" ",
         "(test_differential(method = \"ttest\"), normalize_quant(method = \"median\")).",
         call. = FALSE)
  invisible(TRUE)
}

# Condition label of every matrix column, in column order.
.col_groups <- function(mat, coldata) {
  as.character(coldata$Condition)[match(colnames(mat), as.character(coldata$Unit))]
}

# All pairwise condition comparisons as list(c(reference, test)), in factor order
# (condition_pairs() is the shared, single-condition-safe implementation).
.pairwise_contrasts <- function(conditions) unname(condition_pairs(conditions))

# "B_vs_A" label for a c(A, B) pair: logFC > 0 means higher in B (the test group).
.contrast_label <- function(pair) paste0(pair[2], "_vs_", pair[1])

# Per-row observation counts within one group of columns.
.row_obs <- function(mat, idx) {
  if (length(idx) == 0) return(rep(0L, nrow(mat)))
  as.integer(rowSums(!is.na(mat[, idx, drop = FALSE])))
}

#' Build a feature x unit log2(Area) matrix from `pep_all`
#'
#' Collapses the long `pep_all` table into the quantitative matrix consumed by
#' the statistics engine. `Area` is summed on the **linear** scale across all
#' precursors (charge states, source files) of a feature within a sample —
#' charge states are the same molecule, so summing, not averaging, is the
#' correct aggregation — and only then log2-transformed. Values are subsequently
#' averaged on the log2 scale across the samples belonging to the same `unit`,
#' so technical replicates collapse into their biological replicate instead of
#' being treated as independent observations (pseudo-replication would inflate
#' the residual degrees of freedom and make every p-value anti-conservative).
#'
#' Missing values are kept as `NA` (never 0): `Area == 0` is already mapped to
#' `NA` by the loaders (`compute_log2area()`), and the downstream steps
#' distinguish "not detected" from "detected at low intensity".
#'
#' @param input A `pep_all`-shaped data frame (long format) with at least
#'   `Area`, `Sample`, `Condition` and the `feature`/`unit` columns.
#' @param feature Column used for matrix rows: `"Peptide"` (default, the modified
#'   peptide sequence — the analyte in immunopeptidomics), `"Sequence"`,
#'   `"PeptideID"` (precursor level) or `"ProteinFirst"` (parent protein).
#' @param unit Column used for matrix columns: `"BioReplicate"` (default,
#'   technical replicates averaged), `"Sample"` (every run its own column) or
#'   `"Condition"`.
#'
#' @return A list with `mat` (numeric matrix of log2 intensities, rows named by
#'   `feature`, columns ordered by the factor levels of `unit`, `NA`s preserved)
#'   and `coldata` (one row per matrix column: `Unit`, `Condition`,
#'   `BioReplicate`, `n_Samples`).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' qm <- build_quant_matrix(pep_all, feature = "Peptide", unit = "BioReplicate")
#' dim(qm$mat)
#' }
build_quant_matrix <- function(input, feature = "Peptide", unit = "BioReplicate") {
  feature <- match.arg(feature, c("Peptide", "Sequence", "PeptideID", "ProteinFirst"))
  unit    <- match.arg(unit, c("BioReplicate", "Sample", "Condition"))

  needed <- unique(c(feature, unit, "Sample", "Condition", "Area"))
  missing_cols <- setdiff(needed, names(input))
  if (length(missing_cols) > 0)
    stop("build_quant_matrix(): missing column(s) in `input`: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)

  # Base assignment (not select(Feature = all_of(...))) so feature/unit can point
  # at the same column as Sample/Condition without a name collision.
  dat <- input
  dat$Feature_ <- as.character(dat[[feature]])
  dat$Unit_    <- dat[[unit]]
  dat <- dat[!is.na(dat$Feature_) & nzchar(dat$Feature_) & !is.na(dat$Unit_), , drop = FALSE]
  if (nrow(dat) == 0)
    stop("build_quant_matrix(): no usable rows (all `", feature, "` or `", unit,
         "` values are missing).", call. = FALSE)

  unit_levels <- if (is.factor(dat$Unit_)) levels(droplevels(dat$Unit_))
                 else unique(as.character(dat$Unit_))

  per_sample <- dat |>
    dplyr::group_by(Feature_, Unit_, Sample) |>
    dplyr::summarise(Area = .sum_na(Area), .groups = "drop") |>
    dplyr::mutate(Log2Area = dplyr::if_else(is.na(Area) | Area <= 0, NA_real_, log2(Area)))

  per_unit <- per_sample |>
    dplyr::group_by(Feature_, Unit_) |>
    dplyr::summarise(Log2Area = .mean_na(Log2Area), .groups = "drop") |>
    dplyr::mutate(Unit_ = factor(as.character(Unit_), levels = unit_levels))

  wide <- per_unit |>
    tidyr::pivot_wider(id_cols = Feature_, names_from = Unit_, values_from = Log2Area,
                       names_expand = TRUE)

  mat <- as.matrix(wide[, setdiff(names(wide), "Feature_"), drop = FALSE])
  rownames(mat) <- wide$Feature_
  mat <- mat[, unit_levels[unit_levels %in% colnames(mat)], drop = FALSE]
  mat <- mat[rowSums(!is.na(mat)) > 0, , drop = FALSE]   # drop phantom features

  # one metadata row per matrix column
  has_biorep <- "BioReplicate" %in% names(dat)
  meta <- dat |>
    dplyr::mutate(Unit_ = factor(as.character(Unit_), levels = unit_levels)) |>
    dplyr::group_by(Unit_) |>
    dplyr::summarise(
      Condition    = paste(unique(as.character(Condition)), collapse = "|"),
      BioReplicate = if (has_biorep)
                       paste(unique(as.character(BioReplicate)), collapse = "|") else NA_character_,
      n_Samples    = dplyr::n_distinct(Sample),
      .groups = "drop")
  if (any(grepl("|", meta$Condition, fixed = TRUE)))
    warning("build_quant_matrix(): some `", unit, "` values span several Conditions; ",
            "their Condition label was collapsed with '|'.", call. = FALSE)

  cond_levels <- if (is.factor(input$Condition)) levels(droplevels(input$Condition))
                 else unique(as.character(input$Condition))
  coldata <- data.frame(
    Unit         = factor(as.character(meta$Unit_), levels = unit_levels),
    Condition    = factor(meta$Condition,
                          levels = c(intersect(cond_levels, unique(meta$Condition)),
                                     setdiff(unique(meta$Condition), cond_levels))),
    BioReplicate = meta$BioReplicate,
    n_Samples    = meta$n_Samples,
    stringsAsFactors = FALSE)
  coldata <- coldata[match(colnames(mat), as.character(coldata$Unit)), , drop = FALSE]
  rownames(coldata) <- NULL

  list(mat = mat, coldata = coldata)
}

#' Filter a quantitative matrix to testable features
#'
#' Keeps the features quantified in at least `min_per_group` units of **at least
#' one** condition. A feature observed once cannot support a variance estimate,
#' and in DDA it is dominated by stochastic precursor sampling; requiring the
#' minimum in only one group (rather than all) deliberately retains the
#' condition-exclusive ligands, which the presence/absence track
#' ([test_detection()]) tests instead.
#'
#' @param mat Numeric matrix from [build_quant_matrix()].
#' @param coldata The matching `coldata` data frame (needs `Unit`, `Condition`).
#' @param min_per_group Minimum number of units with a quantified value in at
#'   least one condition. Default `2`.
#'
#' @return The filtered matrix, with attributes `n_dropped` (integer) and
#'   `dropped` (character vector of removed feature names).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' mat_f <- filter_quant(qm$mat, qm$coldata, min_per_group = 2)
#' attr(mat_f, "n_dropped")
#' }
filter_quant <- function(mat, coldata, min_per_group = 2) {
  if (nrow(mat) == 0) {
    attr(mat, "n_dropped") <- 0L
    attr(mat, "dropped") <- character(0)
    return(mat)
  }
  grp <- .col_groups(mat, coldata)
  counts <- vapply(split(seq_len(ncol(mat)), grp), function(idx) .row_obs(mat, idx),
                   integer(nrow(mat)))
  counts <- matrix(counts, nrow = nrow(mat))
  keep <- apply(counts, 1, max) >= min_per_group

  out <- mat[keep, , drop = FALSE]
  attr(out, "n_dropped") <- sum(!keep)
  attr(out, "dropped") <- rownames(mat)[!keep]
  out
}

#' Between-sample normalization of a log2 intensity matrix
#'
#' HLA pulldown yield varies by orders of magnitude between samples, so without
#' between-sample normalization a loading difference is indistinguishable from
#' biology. `"median"` (the default) removes only a per-sample offset — the
#' minimal assumption — and is implemented in base R so the default path has no
#' Bioconductor dependency. `"quantile"`, `"cyclicloess"` and `"scale"` delegate
#' to [limma::normalizeBetweenArrays()]; they additionally force the *shape* of
#' the distributions to agree, which assumes most features do not change — a
#' strong assumption in an on/off ligand landscape, hence not the default.
#'
#' @param mat Numeric matrix of log2 intensities (`NA`s allowed).
#' @param method One of `"median"` (default), `"quantile"`, `"cyclicloess"`,
#'   `"scale"`, `"none"`.
#'
#' @return The normalized matrix (same dimensions and dimnames, `NA`s preserved).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' mat_n <- normalize_quant(mat_f, method = "median")
#' }
normalize_quant <- function(mat, method = c("median", "quantile", "cyclicloess", "scale", "none")) {
  method <- match.arg(method)
  if (method == "none" || nrow(mat) == 0) return(mat)

  if (method == "median") {
    med <- apply(mat, 2, stats::median, na.rm = TRUE)
    med[is.na(med)] <- 0
    grand <- stats::median(med, na.rm = TRUE)
    out <- sweep(mat, 2, med - grand, FUN = "-")
    dimnames(out) <- dimnames(mat)
    return(out)
  }

  .require_limma()
  out <- tryCatch(limma::normalizeBetweenArrays(mat, method = method),
                  error = function(e)
                    stop("normalize_quant(): limma::normalizeBetweenArrays(method = \"", method,
                         "\") failed (", conditionMessage(e), "). Missing values are common in ",
                         "immunopeptidomics; try method = \"median\" or \"quantile\".",
                         call. = FALSE))
  dimnames(out) <- dimnames(mat)
  out
}

#' Left-censored imputation of missing quantitative values
#'
#' Mass-spectrometry missingness is a mixture of MNAR (below the limit of
#' detection) and MAR/stochastic values; in immunopeptidomics a large share is
#' neither, but genuine biology (a ligand presented in one condition only). This
#' function implements the two left-censored conventions used in the field, and
#' the default is to impute nothing — the presence/absence track
#' ([test_detection()]) handles the exclusive features instead of inventing an
#' intensity for them.
#'
#' @param mat Numeric matrix of log2 intensities.
#' @param method `"none"` (default), `"minprob"` (per-sample down-shifted normal
#'   draw, the Perseus convention) or `"mindet"` (deterministic per-sample low
#'   quantile).
#' @param shift Down-shift of the imputed distribution, in sample standard
#'   deviations. Default `1.8` (`"minprob"` only).
#' @param width Standard deviation of the imputed distribution, as a fraction of
#'   the sample standard deviation. Default `0.3` (`"minprob"` only).
#' @param q Quantile used by `"mindet"`. Default `0.01`.
#' @param seed Random seed, so a `"minprob"` run is reproducible. Default `1234`.
#'
#' @return The matrix with missing values filled, carrying a logical attribute
#'   `imputed` (same dimensions) marking which cells were imputed.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' mat_i <- impute_quant(mat_n, method = "minprob")
#' sum(attr(mat_i, "imputed"))
#' }
impute_quant <- function(mat, method = c("none", "minprob", "mindet"),
                         shift = 1.8, width = 0.3, q = 0.01, seed = 1234) {
  method <- match.arg(method)
  was_na <- is.na(mat)
  if (method == "none" || nrow(mat) == 0) {
    attr(mat, "imputed") <- array(FALSE, dim = dim(mat), dimnames = dimnames(mat))
    return(mat)
  }

  out <- mat
  if (method == "minprob") {
    old_seed <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv()) else NULL
    set.seed(seed)
    on.exit(if (!is.null(old_seed)) assign(".Random.seed", old_seed, envir = globalenv()), add = TRUE)
  }
  for (j in seq_len(ncol(out))) {
    x <- out[, j]
    n_miss <- sum(is.na(x))
    if (n_miss == 0 || all(is.na(x))) next
    if (method == "minprob") {
      mu <- mean(x, na.rm = TRUE) - shift * stats::sd(x, na.rm = TRUE)
      sigma <- width * stats::sd(x, na.rm = TRUE)
      if (is.na(mu)) next
      if (is.na(sigma) || sigma <= 0) sigma <- 0
      x[is.na(x)] <- stats::rnorm(n_miss, mean = mu, sd = sigma)
    } else {
      x[is.na(x)] <- stats::quantile(x, probs = q, na.rm = TRUE, names = FALSE)
    }
    out[, j] <- x
  }
  attr(out, "imputed") <- was_na & !is.na(out)
  out
}

#' Differential abundance between conditions
#'
#' Fits a linear model per feature and tests every requested condition pair.
#' With `method = "limma"` (default) the model is `~ 0 + Condition` with
#' pairwise contrasts and empirical-Bayes moderation
#' ([limma::eBayes()], `trend = TRUE`, `robust = TRUE`): with the 3–5 replicates
#' typical of an immunopeptidomics experiment the per-feature variance estimate
#' is extremely noisy, and shrinking it towards a mean-variance trend fitted
#' across all features increases power and controls the FDR better than
#' per-feature t-tests (Smyth 2004; Kammers et al. 2015). `trend = TRUE` accounts
#' for the pronounced intensity-dependent variance of label-free MS,
#' `robust = TRUE` keeps a few wildly variable features from inflating the prior
#' variance (Phipson et al. 2016). limma fits each row on its observed values, so
#' the matrix may (and by default does) contain `NA`s.
#'
#' `method = "ttest"` runs an ordinary Welch t-test per feature and contrast with
#' Benjamini–Hochberg adjustment — a dependency-free fallback and a useful sanity
#' check against the moderated result.
#'
#' @param mat Numeric matrix of (normalized) log2 intensities.
#' @param coldata Column metadata from [build_quant_matrix()] (`Unit`,
#'   `Condition`, `BioReplicate`).
#' @param contrasts List of length-2 character vectors `c(reference, test)`, as
#'   produced by [utils::combn()] on the condition levels. `NULL` (default) uses
#'   all pairwise comparisons in factor order.
#' @param method `"limma"` (default) or `"ttest"`.
#' @param block Optional blocking variable (name of a `coldata` column, or a
#'   vector of length `ncol(mat)`) passed to [limma::duplicateCorrelation()] —
#'   e.g. `"BioReplicate"` when the columns are individual runs, or a patient
#'   identifier in a paired design. Ignored by `method = "ttest"`.
#' @param trend,robust Passed to [limma::eBayes()]. Defaults `TRUE`.
#' @param min_obs Minimum quantified values required *per group* for a feature to
#'   be tested by `method = "ttest"`. Default `2`.
#'
#' @return A data frame with one row per feature and contrast: `Contrast`,
#'   `Feature`, `logFC` (positive = higher in the test condition), `AveExpr`,
#'   `t`, `P.Value`, `adj.P.Val` (BH within contrast), `B` (limma only),
#'   `n_obs_ref`, `n_obs_test`. For `method = "limma"` the fitted `MArrayLM`
#'   object is attached as the attribute `fit` (used for the mean-variance
#'   diagnostic plot).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' res <- test_differential(mat_n, qm$coldata, method = "limma")
#' head(res[order(res$adj.P.Val), ])
#' }
test_differential <- function(mat, coldata, contrasts = NULL,
                              method = c("limma", "ttest"), block = NULL,
                              trend = TRUE, robust = TRUE, min_obs = 2) {
  method <- match.arg(method)
  empty <- data.frame(Contrast = character(0), Feature = character(0), logFC = numeric(0),
                      AveExpr = numeric(0), t = numeric(0), P.Value = numeric(0),
                      adj.P.Val = numeric(0), B = numeric(0),
                      n_obs_ref = integer(0), n_obs_test = integer(0),
                      stringsAsFactors = FALSE)
  if (nrow(mat) == 0) return(empty)

  grp <- .col_groups(mat, coldata)
  if (is.null(contrasts)) contrasts <- .pairwise_contrasts(coldata$Condition)
  if (length(contrasts) == 0) return(empty)

  obs_by_group <- lapply(split(seq_along(grp), grp), function(idx) .row_obs(mat, idx))

  if (method == "ttest") {
    res <- lapply(contrasts, function(pair) {
      i1 <- which(grp == pair[1]); i2 <- which(grp == pair[2])
      n1 <- .row_obs(mat, i1); n2 <- .row_obs(mat, i2)
      testable <- n1 >= min_obs & n2 >= min_obs
      pv <- rep(NA_real_, nrow(mat)); tv <- pv; fc <- pv
      for (i in which(testable)) {
        x1 <- mat[i, i1]; x2 <- mat[i, i2]
        tt <- tryCatch(stats::t.test(x2, x1), error = function(e) NULL)
        if (is.null(tt)) next
        pv[i] <- tt$p.value
        tv[i] <- unname(tt$statistic)
        fc[i] <- mean(x2, na.rm = TRUE) - mean(x1, na.rm = TRUE)
      }
      data.frame(Contrast = .contrast_label(pair), Feature = rownames(mat),
                 logFC = fc, AveExpr = rowMeans(mat[, c(i1, i2), drop = FALSE], na.rm = TRUE),
                 t = tv, P.Value = pv, adj.P.Val = stats::p.adjust(pv, method = "BH"),
                 B = NA_real_, n_obs_ref = n1, n_obs_test = n2,
                 stringsAsFactors = FALSE, row.names = NULL)
    })
    return(do.call(rbind, res))
  }

  .require_limma()
  group <- factor(grp, levels = intersect(levels(coldata$Condition), unique(grp)))
  safe <- make.names(levels(group))
  design <- stats::model.matrix(~ 0 + group)
  colnames(design) <- safe

  if (any(colSums(design) < 2))
    warning("test_differential(): condition(s) with a single unit -- limma cannot ",
            "estimate a within-group variance for them.", call. = FALSE)

  block_vec <- NULL
  if (!is.null(block)) {
    block_vec <- if (length(block) == 1 && block %in% names(coldata))
      as.character(coldata[[block]])[match(colnames(mat), as.character(coldata$Unit))]
    else as.character(block)
  }
  cor_consensus <- NULL
  if (!is.null(block_vec) && dplyr::n_distinct(block_vec) > 1 &&
      dplyr::n_distinct(block_vec) < length(block_vec)) {
    dc <- tryCatch(limma::duplicateCorrelation(mat, design, block = block_vec),
                   error = function(e) NULL)
    if (!is.null(dc) && is.finite(dc$consensus.correlation)) cor_consensus <- dc$consensus.correlation
  }

  fit <- if (is.null(cor_consensus)) limma::lmFit(mat, design)
         else limma::lmFit(mat, design, block = block_vec, correlation = cor_consensus)

  cstr <- vapply(contrasts, function(pair)
    paste0(safe[match(pair[2], levels(group))], "-", safe[match(pair[1], levels(group))]),
    character(1))
  names(cstr) <- vapply(contrasts, .contrast_label, character(1))
  cm <- limma::makeContrasts(contrasts = unname(cstr), levels = design)
  colnames(cm) <- names(cstr)

  fit2 <- limma::eBayes(limma::contrasts.fit(fit, cm), trend = trend, robust = robust)

  res <- lapply(seq_along(contrasts), function(k) {
    pair <- contrasts[[k]]
    tt <- limma::topTable(fit2, coef = names(cstr)[k], number = Inf, sort.by = "none",
                          adjust.method = "BH")
    feats <- rownames(tt)
    data.frame(Contrast = names(cstr)[k], Feature = feats,
               logFC = tt$logFC, AveExpr = tt$AveExpr, t = tt$t,
               P.Value = tt$P.Value, adj.P.Val = tt$adj.P.Val, B = tt$B,
               n_obs_ref  = obs_by_group[[pair[1]]][match(feats, rownames(mat))],
               n_obs_test = obs_by_group[[pair[2]]][match(feats, rownames(mat))],
               stringsAsFactors = FALSE, row.names = NULL)
  })
  out <- do.call(rbind, res)
  attr(out, "fit") <- fit2
  attr(out, "correlation") <- cor_consensus
  out
}

#' Presence/absence test between conditions (Fisher exact)
#'
#' Complements [test_differential()] for the features a quantitative test cannot
#' rank: those detected in one condition and (nearly) absent from the other,
#' which in immunopeptidomics are often the biologically interesting ligands.
#' For every feature and contrast a Fisher exact test is run on the 2x2 table of
#' detected / not-detected units, with Benjamini–Hochberg adjustment within the
#' contrast. Their fold change is undefined by construction — imputing one would
#' make it an artefact of the imputation width — so detection frequency, not
#' intensity, is what is tested.
#'
#' @param mat Numeric matrix (before or after imputation; detection is taken from
#'   the `imputed` attribute when present, otherwise from `!is.na(mat)`).
#' @param coldata Column metadata from [build_quant_matrix()].
#' @param contrasts List of length-2 character vectors, or `NULL` (default) for
#'   all pairwise comparisons.
#'
#' @return A data frame with `Contrast`, `Feature`, `n_det_ref`, `n_tot_ref`,
#'   `n_det_test`, `n_tot_test`, `P.Value_det`, `adj.P.Val_det` and
#'   `Exclusive_in` (the condition name when the feature is detected in one
#'   condition only, `NA` otherwise).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' det <- test_detection(qm$mat, qm$coldata)
#' subset(det, !is.na(Exclusive_in) & adj.P.Val_det < 0.05)
#' }
test_detection <- function(mat, coldata, contrasts = NULL) {
  empty <- data.frame(Contrast = character(0), Feature = character(0),
                      n_det_ref = integer(0), n_tot_ref = integer(0),
                      n_det_test = integer(0), n_tot_test = integer(0),
                      P.Value_det = numeric(0), adj.P.Val_det = numeric(0),
                      Exclusive_in = character(0), stringsAsFactors = FALSE)
  if (nrow(mat) == 0) return(empty)

  imputed <- attr(mat, "imputed")
  detected <- if (!is.null(imputed)) !is.na(mat) & !imputed else !is.na(mat)

  grp <- .col_groups(mat, coldata)
  if (is.null(contrasts)) contrasts <- .pairwise_contrasts(coldata$Condition)
  if (length(contrasts) == 0) return(empty)

  res <- lapply(contrasts, function(pair) {
    i1 <- which(grp == pair[1]); i2 <- which(grp == pair[2])
    n1 <- length(i1); n2 <- length(i2)
    d1 <- as.integer(rowSums(detected[, i1, drop = FALSE]))
    d2 <- as.integer(rowSums(detected[, i2, drop = FALSE]))

    # Only (n1 + 1) * (n2 + 1) distinct 2x2 tables exist: test each one once.
    key <- paste(d1, d2, sep = "_")
    uk <- unique(key)
    pv_lookup <- vapply(uk, function(k) {
      dd <- as.integer(strsplit(k, "_", fixed = TRUE)[[1]])
      tab <- matrix(c(dd[1], n1 - dd[1], dd[2], n2 - dd[2]), nrow = 2)
      stats::fisher.test(tab)$p.value
    }, numeric(1))
    pv <- unname(pv_lookup[key])

    excl <- ifelse(d1 > 0 & d2 == 0, pair[1],
                   ifelse(d2 > 0 & d1 == 0, pair[2], NA_character_))
    data.frame(Contrast = .contrast_label(pair), Feature = rownames(mat),
               n_det_ref = d1, n_tot_ref = n1, n_det_test = d2, n_tot_test = n2,
               P.Value_det = pv, adj.P.Val_det = stats::p.adjust(pv, method = "BH"),
               Exclusive_in = excl, stringsAsFactors = FALSE, row.names = NULL)
  })
  do.call(rbind, res)
}

#' Combine the quantitative and presence/absence tracks
#'
#' Merges [test_differential()] and [test_detection()] into one table per
#' contrast and assigns each feature a `Status`: `up`/`down` when the moderated
#' test passes both the FDR and the fold-change cut-off, `exclusive_up`/
#' `exclusive_down` when the feature is detected in `min_detect` units of one
#' condition and in none of the other, `ns` otherwise.
#'
#' The exclusive flag is deliberately a **detection-count rule, not a p-value
#' cut-off**: with the small designs typical of immunopeptidomics the Fisher
#' exact test cannot reach a small p-value at all (a fully exclusive feature in a
#' 3-vs-3 comparison gives p = 0.1, and no adjustment can improve on that), so
#' gating the flag on the FDR would silently hide every on/off ligand. The Fisher
#' p-values from [test_detection()] are carried along as supporting evidence and
#' become decisive as the number of replicates grows.
#'
#' @param diff_res Output of [test_differential()].
#' @param det_res Output of [test_detection()].
#' @param fdr Adjusted p-value cut-off for the quantitative test. Default `0.05`.
#' @param log2fc Absolute log2 fold-change cut-off. Default `1`.
#' @param min_detect Minimum number of units in which an exclusive feature must be
#'   detected in the condition where it is present (capped at that condition's
#'   number of units). Default `2`.
#'
#' @return A data frame with the columns of both inputs plus `Status`
#'   (factor: `up`, `down`, `exclusive_up`, `exclusive_down`, `ns`).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' results <- combine_quant_results(res, det, fdr = 0.05, log2fc = 1)
#' table(results$Contrast, results$Status)
#' }
combine_quant_results <- function(diff_res, det_res, fdr = 0.05, log2fc = 1, min_detect = 2) {
  status_levels <- c("up", "down", "exclusive_up", "exclusive_down", "ns")
  if (nrow(diff_res) == 0 && nrow(det_res) == 0) {
    out <- cbind(diff_res, det_res[0, setdiff(names(det_res), c("Contrast", "Feature")), drop = FALSE])
    out$Status <- factor(character(0), levels = status_levels)
    return(out)
  }

  out <- dplyr::full_join(diff_res, det_res, by = c("Contrast", "Feature"))
  test_cond <- sub("_vs_.*$", "", out$Contrast)

  # detection counts in the condition where an exclusive feature is present
  is_excl_up <- !is.na(out$Exclusive_in) & out$Exclusive_in == test_cond
  n_det_present <- ifelse(is_excl_up, out$n_det_test, out$n_det_ref)
  n_tot_present <- ifelse(is_excl_up, out$n_tot_test, out$n_tot_ref)
  enough_detect <- !is.na(out$Exclusive_in) & !is.na(n_det_present) &
    n_det_present >= pmin(min_detect, n_tot_present)

  out <- out |>
    dplyr::mutate(
      Status = dplyr::case_when(
        enough_detect & is_excl_up ~ "exclusive_up",
        enough_detect ~ "exclusive_down",
        !is.na(adj.P.Val) & adj.P.Val <= fdr & !is.na(logFC) & logFC >= log2fc ~ "up",
        !is.na(adj.P.Val) & adj.P.Val <= fdr & !is.na(logFC) & logFC <= -log2fc ~ "down",
        TRUE ~ "ns"),
      Status = factor(Status, levels = status_levels))
  attr(out, "fdr") <- fdr
  attr(out, "log2fc") <- log2fc
  attr(out, "min_detect") <- min_detect
  out
}

#' Count significant features per contrast
#'
#' @param results Output of [combine_quant_results()].
#'
#' @return A data frame with one row per contrast and one column per `Status`
#'   level, plus `n_tested` (features with a quantitative p-value).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' summarise_significant(results)
#' }
summarise_significant <- function(results) {
  if (nrow(results) == 0)
    return(data.frame(Contrast = character(0), n_tested = integer(0)))
  results |>
    dplyr::group_by(Contrast) |>
    dplyr::summarise(n_tested = sum(!is.na(P.Value)),
                     up = sum(Status == "up"),
                     down = sum(Status == "down"),
                     exclusive_up = sum(Status == "exclusive_up"),
                     exclusive_down = sum(Status == "exclusive_down"),
                     ns = sum(Status == "ns"),
                     .groups = "drop") |>
    as.data.frame()
}

#' Global permutation test of condition separation (PERMANOVA)
#'
#' Answers "do the conditions separate at all?" before any per-feature claim is
#' made, using the distance-based pseudo-F of Anderson (2001): the ratio of
#' between-group to within-group sums of squared Euclidean distances between
#' samples, with a permutation null obtained by shuffling the condition labels.
#' It is non-parametric, makes no distributional assumption, and needs no extra
#' package. Only features quantified in every column are used, since a distance
#' must be computed on a common feature set.
#'
#' The permutation p-value is bounded below by the number of distinct label
#' assignments: a 3-vs-3 comparison admits only `choose(6, 3) / 2 = 10` of them,
#' so its smallest attainable p-value is about `0.1`, however clean the
#' separation. Read the pseudo-F alongside the p-value in small designs.
#'
#' @param mat Numeric matrix of (normalized, optionally imputed) log2
#'   intensities, features x units.
#' @param coldata Column metadata from [build_quant_matrix()].
#' @param n_perm Number of label permutations. Default `999`.
#' @param seed Random seed. Default `1234`.
#'
#' @return A list with `F` (pseudo-F), `p_value`, `n_perm`, `n_features` (complete
#'   features used) and `n_groups`; `NULL` with a warning when fewer than two
#'   groups or no complete features are available.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' permanova_condition(mat_n, qm$coldata)
#' }
permanova_condition <- function(mat, coldata, n_perm = 999, seed = 1234) {
  grp <- factor(.col_groups(mat, coldata))
  if (dplyr::n_distinct(grp) < 2) {
    warning("permanova_condition(): fewer than two conditions -- test skipped.", call. = FALSE)
    return(NULL)
  }
  complete <- mat[stats::complete.cases(mat), , drop = FALSE]
  if (nrow(complete) < 2) {
    warning("permanova_condition(): fewer than two features quantified in every unit -- ",
            "test skipped (consider ImputeMethod).", call. = FALSE)
    return(NULL)
  }

  d2 <- as.matrix(stats::dist(t(complete)))^2
  n <- ncol(complete)
  a <- nlevels(droplevels(grp))

  pseudo_f <- function(g) {
    ss_total <- sum(d2[upper.tri(d2)]) / n
    ss_within <- sum(vapply(split(seq_len(n), g), function(idx) {
      if (length(idx) < 2) return(0)
      sub <- d2[idx, idx, drop = FALSE]
      sum(sub[upper.tri(sub)]) / length(idx)
    }, numeric(1)))
    ss_between <- ss_total - ss_within
    if (ss_within <= 0) return(NA_real_)
    (ss_between / (a - 1)) / (ss_within / (n - a))
  }

  f_obs <- pseudo_f(droplevels(grp))
  old_seed <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv()) else NULL
  set.seed(seed)
  on.exit(if (!is.null(old_seed)) assign(".Random.seed", old_seed, envir = globalenv()), add = TRUE)
  f_perm <- replicate(n_perm, pseudo_f(droplevels(factor(sample(as.character(grp))))))

  list(F = f_obs,
       p_value = (1 + sum(f_perm >= f_obs, na.rm = TRUE)) / (1 + sum(!is.na(f_perm))),
       n_perm = n_perm, n_features = nrow(complete), n_groups = a)
}
