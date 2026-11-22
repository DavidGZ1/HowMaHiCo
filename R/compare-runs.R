#' Stack the quality scores of several runs into one table
#'
#' One `01_mhc_overview` render scores one subset. `compare_runs()` stacks the
#' per-sample score tables of several renders (different experiments, subsets,
#' or the same QC standard measured over time) into a single long table, so
#' that they can be compared side by side with [summarise_runs()] and
#' [plot_run_trend()].
#'
#' `runs` may mix three kinds of input:
#' * a **score csv** written by `01_mhc_overview` (`<Subset>_scores.csv`, or
#'   `scores.csv` when no `Subset` was set);
#' * a **results folder** holding one or more such files (e.g.
#'   `<FolderResults>/<Subset>`); every `*scores.csv` in it becomes a run;
#' * a **data frame** returned by [score_sample_quality()].
#'
#' For a csv, the companion `<Subset>_01_mhc_overview_input_params.csv` that
#' the same render writes next to it is read when present (for results written
#' before v0.27.0, the old `<Subset>_05_quality_score_input_params.csv`), and its
#' `SampleSet`, `Subset`, `MHCclass`, `ThresholdMode`, `render_timestamp` and
#' `package_version` are attached as columns (`NA` when absent, and always for
#' data-frame input).
#'
#' Composite scores are only comparable when the runs were scored the same way,
#' so a warning names the runs when `MHCclass` or `ThresholdMode` differs between
#' them: the class selects the threshold table, and `"qc_relative"` thresholds
#' are calibrated on each run's own QC samples.
#'
#' @param runs A character vector of score-csv paths and/or results folders, a
#'   single [score_sample_quality()] data frame, or a list of any of these.
#'   Names, when given, become the run labels.
#' @param labels Optional character vector of run labels, one per run after
#'   folders have been expanded. Overrides every other label source.
#' @param order `"input"` (default) keeps the runs in the order given;
#'   `"timestamp"` orders them by `render_timestamp` (oldest first), for a
#'   longitudinal view. Runs without a timestamp go last, with a warning.
#'
#' @return The stacked score table: one row per (run, sample), with the leading
#'   columns `Run` (a factor in run order), `SampleSet`, `Subset`, `MHCclass`,
#'   `ThresholdMode`, `render_timestamp`, `package_version` and `source_file`,
#'   followed by the score columns. Columns are the union over runs: a metric one
#'   run lacks is `NA` there. Labels default to the input names, then
#'   `SampleSet | Subset` from the companion params, then the file name.
#'
#' @seealso [summarise_runs()], [plot_run_trend()], [score_sample_quality()]
#'
#' @export
#'
#' @examples
#' \dontrun{
#' runs <- compare_runs(c(jy = "3_results/dda_jy", plasma = "3_results/dda_plasma"))
#' summarise_runs(runs)
#' plot_run_trend(runs)
#' }
compare_runs <- function(runs, labels = NULL, order = c("input", "timestamp")) {
  order <- match.arg(order)
  if (is.data.frame(runs)) runs <- list(runs)
  if (is.character(runs)) runs <- as.list(runs)
  if (!is.list(runs) || length(runs) == 0)
    stop("'runs' must be score-csv paths, results folders or score data frames.")
  input_names <- names(runs)
  if (is.null(input_names)) input_names <- rep("", length(runs))
  input_names[is.na(input_names)] <- ""

  # expand every input into one entry per run
  entries <- list()
  for (i in seq_along(runs)) {
    x <- runs[[i]]
    if (is.data.frame(x)) {
      entries[[length(entries) + 1]] <- list(data = x, file = NA_character_,
                                             name = input_names[i], index = i)
      next
    }
    if (!is.character(x) || length(x) != 1)
      stop("Element ", i, " of 'runs' is neither a path nor a data frame.")
    files <- if (dir.exists(x)) {
      list.files(x, pattern = "scores\\.csv$", full.names = TRUE)
    } else if (file.exists(x)) {
      x
    } else {
      stop("'", x, "' does not exist.")
    }
    if (length(files) == 0)
      stop("No '*scores.csv' file found in '", x, "'. Render 01_mhc_overview ",
           "for that subset first; it writes <Subset>_scores.csv into its results folder.")
    nm <- input_names[i]
    for (f in files) {
      entries[[length(entries) + 1]] <- list(
        data = NULL, file = f,
        name = if (nzchar(nm) && length(files) > 1)
          paste(nm, .score_file_prefix(f), sep = " | ") else nm,
        index = i)
    }
  }

  if (!is.null(labels) && length(labels) != length(entries))
    stop("'labels' has ", length(labels), " element(s) but there are ",
         length(entries), " run(s).")

  meta_cols <- c("SampleSet", "Subset", "MHCclass", "ThresholdMode",
                 "render_timestamp", "package_version")
  tables <- lapply(seq_along(entries), function(j) {
    e <- entries[[j]]
    tbl <- if (is.null(e$data)) {
      utils::read.csv(e$file, stringsAsFactors = FALSE, check.names = FALSE)
    } else {
      e$data
    }
    if (!"Sample" %in% names(tbl))
      stop("Run ", j, " has no 'Sample' column; is it a score table?")
    meta <- stats::setNames(as.list(rep(NA_character_, length(meta_cols))), meta_cols)
    if (!is.na(e$file)) {
      # the input params of 01_mhc_overview (v0.27.0+) or, for results written
      # before the merge, of the old 05_quality_score report
      pre <- .score_file_prefix(e$file, sep = TRUE)
      pf <- file.path(dirname(e$file),
                      paste0(pre, c("01_mhc_overview", "05_quality_score"),
                             "_input_params.csv"))
      pf <- pf[file.exists(pf)][1]
      if (!is.na(pf)) {
        p <- utils::read.csv(pf, stringsAsFactors = FALSE)
        for (m in meta_cols) {
          v <- p$Value[p$Parameter == m]
          if (length(v) == 1) meta[[m]] <- v
        }
      }
    }
    label <- if (!is.null(labels)) {
      labels[j]
    } else if (nzchar(e$name)) {
      e$name
    } else if (!is.na(meta$SampleSet)) {
      paste(c(meta$SampleSet, if (!is.na(meta$Subset) && nzchar(meta$Subset)) meta$Subset),
            collapse = " | ")
    } else if (!is.na(e$file)) {
      pre <- .score_file_prefix(e$file)
      if (nzchar(pre)) pre else basename(dirname(e$file))
    } else {
      paste0("run", e$index)
    }
    tbl$Sample <- as.character(tbl$Sample)
    for (cc in intersect(c("Condition", "category"), names(tbl)))
      tbl[[cc]] <- as.character(tbl[[cc]])
    lead <- data.frame(Run = rep(label, nrow(tbl)), stringsAsFactors = FALSE)
    for (m in meta_cols) lead[[m]] <- rep(meta[[m]], nrow(tbl))
    lead$source_file <- rep(e$file, nrow(tbl))
    cbind(lead, tbl[, setdiff(names(tbl), names(lead)), drop = FALSE])
  })

  run_labels <- vapply(tables, function(t) t$Run[1], character(1))
  run_labels[is.na(run_labels)] <- paste0("run", which(is.na(run_labels)))
  if (anyDuplicated(run_labels)) {
    new <- make.unique(run_labels, sep = " #")
    warning("Duplicate run labels made unique: ",
            paste(unique(run_labels[duplicated(run_labels)]), collapse = ", "),
            ". Pass 'labels' or name the inputs to control them.", call. = FALSE)
    run_labels <- new
  }
  for (j in seq_along(tables)) tables[[j]]$Run <- rep(run_labels[j], nrow(tables[[j]]))

  run_order <- run_labels
  if (order == "timestamp") {
    ts <- as.POSIXct(vapply(tables, function(t) t$render_timestamp[1], character(1)),
                     tz = "UTC", optional = TRUE)
    if (any(is.na(ts)))
      warning("No render_timestamp for run(s) ",
              paste(run_labels[is.na(ts)], collapse = ", "),
              "; they are placed last.", call. = FALSE)
    run_order <- run_labels[order(ts, na.last = TRUE)]
  }

  out <- dplyr::bind_rows(tables)
  out$Run <- factor(out$Run, levels = run_order)
  out <- out[order(out$Run), , drop = FALSE]
  rownames(out) <- NULL

  for (m in c("MHCclass", "ThresholdMode")) {
    per_run <- tapply(out[[m]], out$Run, function(v) v[1])
    known <- per_run[!is.na(per_run)]
    if (length(unique(known)) > 1)
      warning("Runs were scored with different ", m, " (",
              paste(paste0(names(known), " = ", known), collapse = "; "),
              "); their composite scores are not directly comparable.",
              call. = FALSE)
  }
  out
}

# "<prefix>" of a "<prefix>_scores.csv" file name ("" for a bare scores.csv);
# with sep = TRUE the trailing underscore is kept, ready to paste a sibling name
.score_file_prefix <- function(file, sep = FALSE) {
  pre <- sub("scores\\.csv$", "", basename(file))
  if (sep) pre else sub("_$", "", pre)
}

# metric -> human-readable label for one MHC class (NA / absent -> MHC1). The
# metric keys are identical across classes; a few labels are not (frac_9mer,
# frac_nested_core, frac_charge_1_2), because the metric means something
# different there.
.class_metric_labels <- function(cls = NA) {
  # unname: the class helpers compare with identical(), which a named string fails
  cls <- unname(as.character(cls))
  if (length(cls) != 1 || is.na(cls) || !nzchar(cls)) cls <- "MHC1"
  th <- quality_thresholds_default(cls)
  c(composite_score = "Composite score", stats::setNames(th$label, th$metric))
}

# the classes of the runs in a compare_runs() table (character(0) if unknown)
.run_classes <- function(runs_tbl) {
  if (!"MHCclass" %in% names(runs_tbl)) return(character(0))
  cls <- as.character(stats::na.omit(unique(runs_tbl$MHCclass)))
  cls[nzchar(cls)]
}

# metric -> one label covering every class in the table: where the classes
# label a metric differently (stacking class 1 and class 2 runs), the labels
# are joined with " / " so a shared plot panel does not name only one of them.
# Previously a mixed table silently got the MHC1 labels throughout.
.run_metric_labels <- function(runs_tbl) {
  cls <- .run_classes(runs_tbl)
  if (length(cls) <= 1) return(.class_metric_labels(if (length(cls)) cls else NA))
  per_class <- lapply(cls, .class_metric_labels)
  keys <- names(per_class[[1]])
  stats::setNames(vapply(keys, function(k)
    paste(unique(vapply(per_class, function(l) unname(l[k]), character(1))), collapse = " / "),
    character(1)), keys)
}

#' Summarise stacked quality scores per run
#'
#' Condenses the output of [compare_runs()] to one row per (run, metric): the
#' number of samples with a value, the median and the inter-quartile range, plus
#' the number of samples per traffic-light category of the run.
#'
#' @param runs_tbl Output of [compare_runs()].
#' @param metrics Metric columns to summarise. Default: `composite_score` and
#'   every raw metric of [quality_thresholds_default()] present in `runs_tbl`.
#'
#' @return A data frame with columns `Run`, `metric`, `label`, `n`, `median`,
#'   `q25`, `q75`, `n_Pass`, `n_Warning`, `n_Fail`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' summarise_runs(compare_runs(c("3_results/dda_jy", "3_results/dda_plasma")))
#' }
summarise_runs <- function(runs_tbl, metrics = NULL) {
  labels <- .run_metric_labels(runs_tbl)
  if (is.null(metrics)) metrics <- intersect(names(labels), names(runs_tbl))
  missing <- setdiff(metrics, names(runs_tbl))
  if (length(missing) > 0)
    stop("Metric(s) not in the run table: ", paste(missing, collapse = ", "))

  long <- runs_tbl |>
    dplyr::select(Run, dplyr::all_of(metrics)) |>
    tidyr::pivot_longer(-Run, names_to = "metric", values_to = "value")
  out <- long |>
    dplyr::group_by(Run, metric) |>
    dplyr::summarise(
      n = sum(!is.na(value)),
      median = if (all(is.na(value))) NA_real_ else stats::median(value, na.rm = TRUE),
      q25 = if (all(is.na(value))) NA_real_ else unname(stats::quantile(value, 0.25, na.rm = TRUE)),
      q75 = if (all(is.na(value))) NA_real_ else unname(stats::quantile(value, 0.75, na.rm = TRUE)),
      .groups = "drop") |>
    dplyr::mutate(metric = factor(metric, levels = metrics)) |>
    dplyr::arrange(Run, metric) |>
    dplyr::mutate(metric = as.character(metric))
  # label each row from ITS run's class, so a mixed class-1/class-2 table does
  # not call a class-2 metric by its class-1 name
  run_cls <- if ("MHCclass" %in% names(runs_tbl)) {
    v <- tapply(as.character(runs_tbl$MHCclass), runs_tbl$Run,
                function(x) { x <- x[!is.na(x)]; if (length(x)) x[1] else NA_character_ })
    v[as.character(out$Run)]
  } else rep(NA_character_, nrow(out))
  lab_cache <- list()
  out$label <- vapply(seq_len(nrow(out)), function(i) {
    key <- if (is.na(run_cls[i])) "<NA>" else run_cls[i]
    if (is.null(lab_cache[[key]])) lab_cache[[key]] <<- .class_metric_labels(run_cls[i])
    l <- lab_cache[[key]]
    m <- out$metric[i]
    if (m %in% names(l)) unname(l[m]) else m
  }, character(1))
  out <- dplyr::relocate(out, label, .after = metric)

  cats <- c("Pass", "Warning", "Fail")
  cat_counts <- lapply(cats, function(k) {
    if (!"category" %in% names(runs_tbl)) return(rep(NA_integer_, nlevels(runs_tbl$Run)))
    as.integer(tapply(runs_tbl$category %in% k, runs_tbl$Run, sum))
  })
  cat_tbl <- data.frame(Run = factor(levels(runs_tbl$Run), levels = levels(runs_tbl$Run)))
  for (k in seq_along(cats)) cat_tbl[[paste0("n_", cats[k])]] <- cat_counts[[k]]
  out <- dplyr::left_join(out, cat_tbl, by = "Run")
  as.data.frame(out)
}
