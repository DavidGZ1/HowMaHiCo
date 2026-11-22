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

#' Glossary of the `pep_all` columns
#'
#' Reference table describing every core column of the unified `pep_all` schema,
#' plus the engine-specific caveats that are easy to misread (DIA-NN's dummy
#' `ppm`, its computed rather than observed `Mass`, `Accession` being a protein
#' *group* for some engines only). Rendered by the reports' Glossary section and
#' reproduced in the README, so the three places that document the schema cannot
#' drift apart.
#'
#' @return A data frame with columns `Column`, `Meaning` and `Notes`, in schema
#'   order (sample identity, protein, peptide, scores/quantities, modifications,
#'   physicochemical, provenance).
#'
#' @export
#'
#' @examples
#' pep_all_glossary()
#' subset(pep_all_glossary(), Column %in% c("Peptide", "Sequence"))
pep_all_glossary <- function() {
  g <- function(column, meaning, notes = "") c(column, meaning, notes)
  rows <- list(
    g("Condition", "Experimental group the sample belongs to",
      "From the annotation table; factor order = annotation row order"),
    g("BioReplicate", "Biological replicate within a Condition",
      "From the annotation table"),
    g("TechReplicate", "Technical/injection replicate within a BioReplicate",
      "From the annotation table"),
    g("Sample", "The analysed sample - the unit most plots are drawn per",
      "From the annotation table"),
    g("Sample_ID", "Free-text human-readable sample identifier",
      "Optional; get_annot_sampleid() can fill it from a HyStar sample list"),
    g("Accession", "Protein accession(s) the peptide was assigned to",
      "A protein GROUP for DIA-NN (';'-list) and PEAKS (':'-list); a single sp|ID|ENTRY string for FragPipe"),
    g("ProteinFirst", "Leading protein of the group", "Default protein key of build_prot_all()"),
    g("GeneFirst", "Leading gene name of the group", "Empty when the engine reports no gene"),
    g("OrganismFirst", "Organism suffix parsed from the leading accession", ""),
    g("Peptide", "Peptide as reported, modifications included",
      "Two peptidoforms of one sequence are two different peptides"),
    g("Sequence", "Stripped amino-acid sequence, no modifications",
      "The 'sequences' counted in Venn/UpSet plots"),
    g("Length", "Number of amino acids in Sequence", ""),
    g("Length_range", "Whether Length falls in the expected ligand window",
      "Window from MHCclass (or ShortPeptideLengthMin/Max); defines pep_short"),
    g("Score", "Search-engine confidence score",
      "Engine-specific and NOT comparable across engines: FragPipe hyperscore, DIA-NN Q.Value (lower is better), PEAKS -10lgP"),
    g("Area", "Precursor peak area (linear scale)",
      "NA when the engine reported zero - see compute_log2area()"),
    g("Log2Area", "log2 of Area", "NA for zero/absent Area in every loader"),
    g("PTM", "Modification token(s) as the engine wrote them",
      "UniMod accessions for DIA-NN, delta masses for FragPipe/PEAKS; translate_ptm() maps both to names at plot time"),
    g("Charge", "Precursor charge state, formatted '+ n'", ""),
    g("Nter", "First residue of Sequence", ""),
    g("Cter", "Last residue of Sequence",
      "C-terminal K/R fraction is a tryptic-background diagnostic in the quality score"),
    g("RT", "Retention time", "Minutes, as reported by the engine"),
    g("invk0", "Ion mobility, 1/k0", "timsTOF only; FAIMS compensation voltage is substituted for faims_orbi"),
    g("Mass", "Precursor mass",
      "Observed/calibrated for FragPipe and PEAKS; COMPUTED from Precursor.Mz and charge for DIA-NN"),
    g("ppm", "Mass error in parts per million",
      "A hardcoded dummy 0 for DIA-NN, which reports no observed precursor m/z; dropped from the quality score there"),
    g("m_z", "Precursor mass-to-charge ratio", "The library value for DIA-NN"),
    g("Source_file", "Raw file / run the observation came from", "Extracted by extract_run_name()"),
    g("Source_File_ID", "Engine's own run identifier", ""),
    g("Precursor_Id", "Engine's precursor identifier", "DIA-NN"),
    g("Found_By", "Search engine that produced the row",
      "'FragPipe', 'DIA-NN', 'PEAKS', or the dictionary's value for custom input"),
    g("PeptideID", "Composite peptide identifier used for joins and counting", "")
  )
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("Column", "Meaning", "Notes")
  out
}

#' Glossary of the physicochemical descriptors
#'
#' One row per descriptor column of [peptide_properties()]: what it measures,
#' how to read it for MHC ligands, and how it is computed. It is the single
#' source of the descriptor documentation the `04_pepchem` report renders in
#' its glossary (through `inst/rmarkdown/shared/glossary.Rmd`), next to the
#' [pep_all_glossary()] table.
#'
#' The `frac_*` rows are generated from the amino-acid classes the composition
#' code uses, so the residues listed can never drift from what is computed.
#'
#' @param ph pH quoted for the net `Charge` descriptor (the report's
#'   `ChargePh` param). Default `7.4`.
#'
#' @return A data frame with columns `Descriptor`, `Meaning`, `Interpretation`
#'   and `Computed`, one row per descriptor column of [peptide_properties()]
#'   (all but `Sequence`).
#'
#' @export
#'
#' @examples
#' pepchem_glossary()
#' subset(pepchem_glossary(), Descriptor == "GRAVY")
pepchem_glossary <- function(ph = 7.4) {
  g <- function(descriptor, meaning, interpretation, computed)
    c(descriptor, meaning, interpretation, computed)
  rows <- list(
    g("Length", "Number of amino acids",
      "MHC-I ligands peak at 9 AAs (8-11 for most alleles; 8 for mouse H-2Kb); MHC-II ligands are 12-25 AAs and ragged",
      "nchar(Sequence)"),
    g("GRAVY", "Grand average of hydropathy: mean Kyte-Doolittle hydropathy of the residues",
      "Positive = hydrophobic, negative = hydrophilic. Shifts with allele anchor preferences and with LC retention",
      "Peptides::hydrophobicity(scale = \"KyteDoolittle\") (Kyte & Doolittle 1982)"),
    g("MW", "Molecular weight in Da",
      "Tracks Length closely; useful mainly to spot unusual composition at fixed length",
      "Peptides::mw() (average masses)"),
    g("pI", "Isoelectric point: the pH at which the net charge is zero",
      "Basic anchors (K/R, e.g. HLA-A*03/A*11) raise it; acidic residues lower it",
      "Peptides::pI() (EMBOSS pK scale)"),
    g("Charge", paste0("Theoretical net charge at pH ", ph),
      "Related to, but not the same as, the precursor charge state the instrument sees",
      paste0("Peptides::charge(pH = ", ph, ") (Lehninger pK scale); set by ChargePh")),
    g("Boman", "Boman index: potential to bind other proteins (sum of residue solubility values / length)",
      "Higher (about > 2.5) suggests higher protein-binding potential; low or negative for hydrophobic peptides",
      "Peptides::boman() (Boman 2003)"),
    g("HydrophobicMoment", "Amphipathicity: hydrophobic moment of the sequence as an alpha-helix",
      "High values mean one face hydrophobic, the other polar. Mostly descriptive for short linear ligands",
      "Peptides::hmoment() (Eisenberg scale, 100 degrees per residue, window 11)"),
    g("InstabilityIndex", "Guruprasad instability index, from dipeptide composition",
      "Above 40 is called 'unstable' for proteins; the cut-off was not derived for short peptides, so compare between Conditions rather than against 40",
      "Peptides::instaIndex() (Guruprasad et al. 1990)"),
    g("AliphaticIndex", "Relative volume occupied by aliphatic side chains (A, V, I, L)",
      "Higher with I/L/V-rich peptides, e.g. hydrophobic C-terminal anchors",
      "Peptides::aIndex() (Ikai 1980)")
  )
  classes <- .aa_classes()
  frac_rows <- lapply(names(classes), function(cl)
    g(paste0("frac_", cl),
      paste0("Fraction of residues in the ", cl, " class (",
             paste(classes[[cl]], collapse = ", "), ")"),
      "Compare between Conditions; classes overlap, so fractions do not sum to 1",
      "Residue counts / number of standard residues (X, B, Z, U ignored)"))
  out <- as.data.frame(do.call(rbind, c(rows, frac_rows)), stringsAsFactors = FALSE)
  names(out) <- c("Descriptor", "Meaning", "Interpretation", "Computed")
  out
}
