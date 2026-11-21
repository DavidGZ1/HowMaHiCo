# Protein-level view of the peptide repertoire
#
# Condenses the peptide-level `pep_all` table to one row per (protein, Sample):
# the `prot_all` table behind the 02_prot_all report. Everything else in the
# package is peptide-centric; protein information existed only as `n_Proteins`
# columns inside the ID-count tables and two protein x sample log2 matrices.
#
# Three design points drive this file.
#
# 1. THE PROTEIN KEY IS A CHOICE, NOT A GIVEN. `Accession` is a protein *group*
#    only for DIA-NN (a ";"-list) and PEAKS (a ":"-list); FragPipe puts a single
#    "sp|ID|ENTRY" string there. `ProteinFirst` is the leading accession, except
#    for DIA-NN where it is `Protein.Group` and may itself be ";"-joined. So the
#    grouping column is a parameter, defaulting to `ProteinFirst`.
#
#    Note the existing reports count proteins as n_distinct(Accession)
#    (count_ids(), check_ids_global(), qc_metrics_by_sample()), so a prot_all
#    keyed on ProteinFirst does not always reproduce the protein count shown in
#    01_mhc_overview. The report says so rather than letting the two disagree.
#
# 2. A SHORT NON-TRYPTIC LIGAND OFTEN MAPS TO SEVERAL PROTEINS, and neither
#    convention for handling that is right: "leading" attributes it to one
#    somewhat arbitrary protein but keeps peptide totals reconcilable, "all"
#    counts it for every candidate but inflates them. Both are offered. The
#    mapped-protein list lives in a different column per engine, so
#    .mapped_protein_column() dispatches on `Found_By`.
#
# 3. WHERE THE SEARCH ENGINE ALREADY REPORTS PROTEIN-LEVEL VALUES, THEY ARE
#    CARRIED THROUGH rather than only recomputed. DIA-NN reports PG.MaxLFQ and
#    friends; those columns already sit unused in `pep_all`. They are scoped to
#    (protein group, run), so within a group they are normally constant and are
#    carried by a unique-within-group rule that returns NA rather than inventing
#    a number when they genuinely differ.

# ---- internal helpers -------------------------------------------------------

# Engine-reported protein/gene-level columns, both DIA-NN naming generations.
# Kept as one list so the loader's any_of() and prot_engine_columns() cannot
# drift apart.
.diann_protein_quant <- function()
  c("PG.Quantity", "PG.Normalised", "PG.MaxLFQ",
    "PG.Abundance", "PG.NormalisedAbundance", "PG.NormalizedAbundance",
    "Genes.Quantity", "Genes.Normalised", "Genes.MaxLFQ", "Genes.MaxLFQ.Unique",
    "Genes.Abundance", "Genes.NormalisedAbundance")

.diann_protein_qvalue <- function()
  c("Protein.Q.Value", "PG.Q.Value", "Global.PG.Q.Value", "GG.Q.Value",
    "Lib.PG.Q.Value")

# Which column holds the full mapped-protein list, and what separates its
# entries. Dispatches on Found_By, which every loader sets.
.mapped_protein_column <- function(input) {
  found <- unique(as.character(input$Found_By))
  found <- found[!is.na(found)]
  engine <- if (length(found) == 1) found else NA_character_

  spec <- switch(
    as.character(engine),
    "FragPipe" = list(column = "Mapped_Proteins", sep = "[,;]\\s*", leading = TRUE),
    "DIA-NN"   = list(column = "Accession",       sep = ";",         leading = FALSE),
    "PEAKS"    = list(column = "Accession",       sep = ":",         leading = FALSE),
    NULL)

  if (is.null(spec) || !spec$column %in% names(input)) return(NULL)
  spec
}

# TRUE/FALSE per row for "this peptide is unique to its protein", from whichever
# flag the engine provides; NA when neither is present (PEAKS, custom).
.unique_peptide_flag <- function(input) {
  if ("Is_Unique" %in% names(input)) {
    flag <- toupper(trimws(as.character(input$Is_Unique)))
    return(flag %in% c("Y", "YES", "TRUE", "1"))
  }
  if ("Proteotypic" %in% names(input)) {
    return(suppressWarnings(as.numeric(input$Proteotypic)) == 1)
  }
  rep(NA, nrow(input))
}

# The single value of `x` within a group, or NA when it genuinely varies. Never
# averages and never silently takes the first: an engine-reported protein
# quantity that differs within the group means the group is not the scope that
# value was computed for.
.unique_or_na <- function(x) {
  u <- unique(x[!is.na(x)])
  if (length(u) == 1) u[[1]] else if (is.numeric(x)) NA_real_ else NA_character_
}

# Sum on the linear scale, keeping an all-missing group missing.
.sum_area <- function(x) if (all(is.na(x))) NA_real_ else sum(x, na.rm = TRUE)

#' Engine-reported protein-level column names
#'
#' The DIA-NN protein- and gene-level quantity and q-value columns that
#' [parse_diann()] passes through, listed in one place so the loader's
#' `dplyr::any_of()` selection and [prot_engine_columns()] cannot drift apart.
#'
#' Both DIA-NN naming generations are included — the fields were renamed between
#' releases (`PG.Quantity` became `PG.Abundance`, `PG.Normalised` became
#' `PG.NormalisedAbundance`) — so whichever spelling a report carries is kept.
#'
#' @return A character vector of column names.
#'
#' @export
#'
#' @examples
#' diann_protein_columns()
diann_protein_columns <- function()
  c(.diann_protein_quant(), .diann_protein_qvalue())

#' Protein-level columns the search engine reported
#'
#' Reports which engine-computed protein-level columns are present in a
#' `pep_all` table, so [build_prot_all()] can carry them through and the report
#' can show them next to the values recomputed from peptides.
#'
#' In practice this means DIA-NN, which reports protein-group quantities
#' (`PG.MaxLFQ` and friends) alongside every precursor. FragPipe's `psm.tsv`
#' reports no protein quantity — that lives in `protein.tsv`, which this package
#' does not read — and contributes annotation only; PEAKS' `peptide.csv` and the
#' custom-dictionary path contribute nothing.
#'
#' @param input A `pep_all`-shaped data frame.
#'
#' @return A named list with three character vectors: `quantity`, `qvalue` and
#'   `annotation`. Any of them may be empty, and all three are empty when the
#'   search engine reported nothing at protein level.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' prot_engine_columns(pep_all)
#' }
prot_engine_columns <- function(input) {
  annotation <- c("Protein.Ids", "Protein.Names", "Protein_Description",
                  "Mapped_Genes", "Mapped_Proteins")
  list(quantity   = intersect(.diann_protein_quant(), names(input)),
       qvalue     = intersect(.diann_protein_qvalue(), names(input)),
       annotation = intersect(annotation, names(input)))
}

#' Expand peptides onto every protein they map to
#'
#' A short, non-tryptic HLA ligand frequently maps to more than one protein.
#' This returns the peptide-to-protein mapping implied by the search engine's
#' own list of mapped proteins, one row per (peptide row, protein).
#'
#' The list lives in a different column per engine — FragPipe's
#' `Mapped_Proteins`, DIA-NN's and PEAKS' `Accession` — with a different
#' separator, so the source is resolved from the `Found_By` column. When the
#' table carries no such list (PEAKS' peptide export, the custom-dictionary path,
#' or a FragPipe run whose `Mapped_Proteins` is empty) the leading protein is
#' returned with a warning, which is the same answer `multi_mapping = "leading"`
#' would give.
#'
#' @param input A `pep_all`-shaped data frame.
#' @param protein Column holding the leading protein. Default `"ProteinFirst"`.
#'
#' @return `input` with the `protein` column replaced by one row per mapped
#'   protein, plus a logical `Protein_shared` marking peptides that mapped to
#'   more than one.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' expand_mapped_proteins(pep_all)
#' }
expand_mapped_proteins <- function(input, protein = "ProteinFirst") {
  if (!protein %in% names(input))
    stop("expand_mapped_proteins(): `input` has no column '", protein, "'.",
         call. = FALSE)

  spec <- .mapped_protein_column(input)
  lead <- as.character(input[[protein]])

  mapped <- if (is.null(spec)) NULL else {
    raw <- trimws(as.character(input[[spec$column]]))
    if (all(is.na(raw) | !nzchar(raw))) NULL else strsplit(raw, spec$sep)
  }

  if (is.null(mapped)) {
    warning("expand_mapped_proteins(): this table carries no mapped-protein ",
            "list (search engine '",
            paste(unique(stats::na.omit(as.character(input$Found_By))), collapse = "/"),
            "'), so every peptide is attributed to its leading protein only.",
            call. = FALSE)
    out <- input
    out$Protein_shared <- FALSE
    return(out)
  }

  # An empty entry falls back to the leading protein so no peptide is lost.
  mapped <- lapply(seq_along(mapped), function(i) {
    m <- trimws(mapped[[i]])
    m <- m[!is.na(m) & nzchar(m)]
    if (length(m) == 0) lead[i] else unique(c(lead[i], m))
  })

  times <- vapply(mapped, length, integer(1))
  out <- input[rep(seq_len(nrow(input)), times), , drop = FALSE]
  out[[protein]] <- unlist(mapped, use.names = FALSE)
  out$Protein_shared <- rep(times > 1, times)
  rownames(out) <- NULL
  out
}

#' Condense `pep_all` to one row per protein and sample
#'
#' Builds the `prot_all` table behind the `02_prot_all` report: for every
#' (protein, `Sample`) pair, how many ligands it contributes and their summed
#' intensity, plus the protein annotation and any protein-level value the search
#' engine itself reported.
#'
#' `Area` is summed on the **linear** scale within a sample and log2-transformed
#' afterwards, matching [build_quant_matrix()]. Note that the older
#' `get_mat_log2area(pep_all, ProteinFirst, ...)` route used by `00_mhc_report`
#' and `01_mhc_overview` instead *averages* `Log2Area`; the two are not interchangeable.
#'
#' @param input A `pep_all`-shaped data frame.
#' @param protein Grouping column: `"ProteinFirst"` (default), `"GeneFirst"` or
#'   `"Accession"`. Which is appropriate depends on the search engine — see the
#'   report's methods section.
#' @param multi_mapping `"leading"` (default) counts each peptide once, for its
#'   leading protein; `"all"` counts it for every protein it maps to, via
#'   [expand_mapped_proteins()]. Under `"all"` the per-protein peptide counts
#'   deliberately no longer sum to the number of peptides in the dataset.
#' @param engine_columns Carry through the protein-level columns the search
#'   engine reported (see [prot_engine_columns()]). Default `TRUE`.
#'
#' @return A data frame with one row per (protein, `Sample`): `Protein`,
#'   `Sample`, `Condition`, `BioReplicate`, the protein annotation columns
#'   present in `input`, `n_Peptides`, `n_Sequences`, `n_Peptides_unique`,
#'   `n_Peptides_shared`, `Area`, `Log2Area`, plus any engine-reported columns.
#'   Zero rows, correctly typed, when `input` has none.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' prot_all <- build_prot_all(pep_short)
#' build_prot_all(pep_short, protein = "GeneFirst", multi_mapping = "all")
#' }
build_prot_all <- function(input, protein = c("ProteinFirst", "GeneFirst", "Accession"),
                           multi_mapping = c("leading", "all"),
                           engine_columns = TRUE) {
  protein <- match.arg(protein)
  multi_mapping <- match.arg(multi_mapping)

  needed <- c(protein, "Sample", "Peptide", "Sequence")
  missing_cols <- setdiff(needed, names(input))
  if (length(missing_cols) > 0)
    stop("build_prot_all(): missing column(s) in `input`: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)

  annot_cols <- intersect(c("Sample", "BioReplicate", "Condition"), names(input))
  extra <- if (isTRUE(engine_columns)) prot_engine_columns(input) else
    list(quantity = character(0), qvalue = character(0), annotation = character(0))
  carried <- unique(c(setdiff(intersect(c("Accession", "GeneFirst", "OrganismFirst"),
                                        names(input)), protein),
                      extra$annotation, extra$quantity, extra$qvalue))

  dat <- input
  if (multi_mapping == "all") dat <- expand_mapped_proteins(dat, protein = protein)
  if (!"Protein_shared" %in% names(dat))
    dat$Protein_shared <- rep(FALSE, nrow(dat))   # rep(): a 0-row df rejects a scalar
  dat$Peptide_unique_ <- .unique_peptide_flag(dat)

  dat$Protein_ <- as.character(dat[[protein]])
  dat <- dat[!is.na(dat$Protein_) & nzchar(dat$Protein_), , drop = FALSE]

  empty <- data.frame(Protein = character(0), stringsAsFactors = FALSE)
  if (nrow(dat) == 0) {
    for (nm in c(annot_cols, carried)) empty[[nm]] <- character(0)
    for (nm in c("n_Peptides", "n_Sequences", "n_Peptides_unique",
                 "n_Peptides_shared", "Area", "Log2Area"))
      empty[[nm]] <- numeric(0)
    attr(empty, "protein") <- protein
    attr(empty, "multi_mapping") <- multi_mapping
    return(empty)
  }

  out <- dat |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c("Protein_", annot_cols)))) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(carried), .unique_or_na),
      n_Peptides        = dplyr::n_distinct(.data$Peptide),
      n_Sequences       = dplyr::n_distinct(.data$Sequence),
      n_Peptides_unique = if (all(is.na(.data$Peptide_unique_))) NA_integer_
                          else dplyr::n_distinct(.data$Peptide[
                            !is.na(.data$Peptide_unique_) & .data$Peptide_unique_]),
      n_Peptides_shared = dplyr::n_distinct(.data$Peptide[.data$Protein_shared]),
      Area              = if ("Area" %in% names(dat)) .sum_area(.data$Area) else NA_real_,
      .groups = "drop") |>
    dplyr::rename(Protein = "Protein_") |>
    dplyr::mutate(Log2Area = dplyr::if_else(is.na(.data$Area) | .data$Area <= 0,
                                            NA_real_, log2(.data$Area))) |>
    as.data.frame()

  # How often an engine-reported value was dropped because it varied within a
  # group -- normally zero, non-zero when `protein` is coarser than the scope
  # the engine computed the value for (e.g. gene-level grouping of PG.* values).
  if (length(c(extra$quantity, extra$qvalue)) > 0) {
    varied <- vapply(c(extra$quantity, extra$qvalue), function(nm) {
      sum(tapply(dat[[nm]], list(dat$Protein_, as.character(dat$Sample)),
                 function(x) length(unique(x[!is.na(x)])) > 1), na.rm = TRUE)
    }, numeric(1))
    varied <- varied[varied > 0]
    if (length(varied) > 0) attr(out, "engine_columns_varied") <- varied
  }

  attr(out, "protein") <- protein
  attr(out, "multi_mapping") <- multi_mapping
  rownames(out) <- NULL
  out
}

#' Condense the protein table across samples
#'
#' Collapses [build_prot_all()] to one row per (protein, group): in how many
#' samples of that group the protein was seen, the mean +/- sd number of ligands
#' it contributed, and the total intensity.
#'
#' @param prot_all Output of [build_prot_all()].
#' @param by Grouping column. Default `"Condition"`.
#'
#' @return A data frame with `Protein`, the `by` column, `n_Samples_detected`,
#'   `n_Peptides_mean`, `n_Peptides_sd`, `n_Peptides_total` and `Area_total`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' summarise_prot_all(build_prot_all(pep_short))
#' }
summarise_prot_all <- function(prot_all, by = "Condition") {
  if (!by %in% names(prot_all))
    stop("summarise_prot_all(): `prot_all` has no column '", by, "'.", call. = FALSE)

  prot_all |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c("Protein", by)))) |>
    dplyr::summarise(
      n_Samples_detected = sum(.data$n_Peptides > 0, na.rm = TRUE),
      n_Peptides_mean    = mean(.data$n_Peptides, na.rm = TRUE),
      n_Peptides_sd      = if (sum(!is.na(.data$n_Peptides)) < 2) NA_real_
                           else stats::sd(.data$n_Peptides, na.rm = TRUE),
      n_Peptides_total   = sum(.data$n_Peptides, na.rm = TRUE),
      Area_total         = .sum_area(.data$Area),
      .groups = "drop") |>
    as.data.frame()
}

#' Rank the most prolific source proteins
#'
#' The proteins contributing the most ligands (or the most intensity), pooled
#' across the whole table. In an immunopeptidome a small number of source
#' proteins usually dominate, and this is the table that shows which.
#'
#' @param prot_all Output of [build_prot_all()].
#' @param n Number of proteins to return. Default `25`.
#' @param by Ranking column: `"n_Peptides"` (default) or `"Area"`.
#' @param min_peptides Drop proteins contributing fewer ligands than this.
#'   Default `1`.
#'
#' @return A data frame with one row per protein: `Protein`, `n_Peptides`,
#'   `n_Sequences`, `n_Samples`, `Area`, ordered by `by` descending.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' top_source_proteins(build_prot_all(pep_short), n = 25)
#' }
top_source_proteins <- function(prot_all, n = 25, by = c("n_Peptides", "Area"),
                                min_peptides = 1) {
  by <- match.arg(by)
  if (nrow(prot_all) == 0) return(prot_all[0, , drop = FALSE])

  out <- prot_all |>
    dplyr::group_by(.data$Protein) |>
    dplyr::summarise(n_Peptides  = sum(.data$n_Peptides, na.rm = TRUE),
                     n_Sequences = sum(.data$n_Sequences, na.rm = TRUE),
                     n_Samples   = dplyr::n_distinct(.data$Sample),
                     Area        = .sum_area(.data$Area),
                     .groups = "drop") |>
    dplyr::filter(.data$n_Peptides >= min_peptides) |>
    as.data.frame()

  out <- out[order(out[[by]], decreasing = TRUE, na.last = TRUE), , drop = FALSE]
  rownames(out) <- NULL
  utils::head(out, n)
}
