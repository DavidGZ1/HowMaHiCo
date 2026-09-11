# Tests for the protein-level engine (R/prot-all.R). Like test-pepchem.R and
# test-quant-stats.R these work on small hand-built inputs: the point is the
# aggregation rules, not the search-engine parsing, which the loader tests cover.
#
# The shipped simulated dataset cannot exercise multi-mapping -- its
# `Mapped Proteins` column is blank in every row -- and the shipped
# make_diann_report_raw() helper sets every PG.* column to NA_real_, so it has
# the engine columns but no values. Both are therefore built here.

# 2 samples x 4 peptides. P1 is a two-protein group (P1;PX) so it exercises
# multi-mapping; P1 and P2 share a gene so they exercise the coarser grouping.
make_diann_pep_all <- function() {
  data.frame(
    Found_By     = "DIA-NN",
    Sample       = rep(c("S1", "S2"), each = 4),
    BioReplicate = rep(c("S1", "S2"), each = 4),
    Condition    = rep(c("CTRL", "TREAT"), each = 4),
    ProteinFirst = rep(c("P1", "P1", "P2", "P2"), 2),
    Accession    = rep(c("P1;PX", "P1;PX", "P2", "P2"), 2),
    GeneFirst    = rep("G1", 8),
    Peptide      = rep(c("AAA", "BBB", "CCC", "DDD"), 2),
    Sequence     = rep(c("AAA", "BBB", "CCC", "DDD"), 2),
    Area         = c(10, 20, 30, 40, 50, 60, 70, 80),
    PG.MaxLFQ    = rep(c(100, 100, 200, 200), 2),
    PG.Q.Value   = rep(c(0.01, 0.01, 0.02, 0.02), 2),
    Proteotypic  = c(1, 0, 1, 1, 1, 0, 1, 1),
    stringsAsFactors = FALSE)
}

make_fragpipe_pep_all <- function() {
  data.frame(
    Found_By        = "FragPipe",
    Sample          = rep(c("S1", "S2"), each = 2),
    BioReplicate    = rep(c("S1", "S2"), each = 2),
    Condition       = rep(c("CTRL", "TREAT"), each = 2),
    ProteinFirst    = rep(c("P1", "P2"), 2),
    Accession       = rep(c("sp|P1|A_HUMAN", "sp|P2|B_HUMAN"), 2),
    GeneFirst       = rep(c("GA", "GB"), 2),
    Mapped_Proteins = rep(c("PX, PY", ""), 2),
    Is_Unique       = rep(c("N", "Y"), 2),
    Peptide         = rep(c("AAA", "CCC"), 2),
    Sequence        = rep(c("AAA", "CCC"), 2),
    Area            = c(10, 30, 50, 70),
    stringsAsFactors = FALSE)
}

test_that("build_prot_all collapses peptides and sums Area on the linear scale", {
  out <- build_prot_all(make_diann_pep_all())

  expect_equal(nrow(out), 4L)                       # 2 proteins x 2 samples
  expect_setequal(out$Protein, c("P1", "P2"))
  expect_true(all(out$n_Peptides == 2))
  expect_true(all(out$n_Sequences == 2))

  # P1 in S1: 10 + 20 summed on the LINEAR scale, not a mean of log2 values
  p1s1 <- out[out$Protein == "P1" & out$Sample == "S1", ]
  expect_equal(p1s1$Area, 30)
  expect_equal(p1s1$Log2Area, log2(30))
  expect_false(isTRUE(all.equal(p1s1$Log2Area, mean(log2(c(10, 20))))))

  expect_equal(attr(out, "protein"), "ProteinFirst")
  expect_equal(attr(out, "multi_mapping"), "leading")
})

test_that("build_prot_all regroups on the chosen ProteinFeature", {
  dat <- make_diann_pep_all()

  by_protein <- build_prot_all(dat, protein = "ProteinFirst")
  by_gene    <- build_prot_all(dat, protein = "GeneFirst")
  by_acc     <- build_prot_all(dat, protein = "Accession")

  expect_setequal(by_protein$Protein, c("P1", "P2"))
  expect_setequal(by_gene$Protein, "G1")            # both proteins share the gene
  expect_setequal(by_acc$Protein, c("P1;PX", "P2"))

  # the gene pools all four peptides of a sample
  expect_true(all(by_gene$n_Peptides == 4))
  expect_equal(by_gene$Area[by_gene$Sample == "S1"], 10 + 20 + 30 + 40)
})

test_that("multi_mapping = 'all' counts a shared peptide for every protein", {
  dat <- make_diann_pep_all()

  lead <- build_prot_all(dat, multi_mapping = "leading")
  all_ <- build_prot_all(dat, multi_mapping = "all")

  expect_setequal(lead$Protein, c("P1", "P2"))
  expect_setequal(all_$Protein, c("P1", "P2", "PX"))   # PX picks up the shared ligands

  # under "leading" the per-protein counts reconcile with the peptide count;
  # under "all" they deliberately exceed it
  n_peptide_sample <- nrow(unique(dat[, c("Peptide", "Sample")]))
  expect_equal(sum(lead$n_Peptides), n_peptide_sample)
  expect_gt(sum(all_$n_Peptides), n_peptide_sample)

  expect_equal(attr(all_, "multi_mapping"), "all")
  # the shared ligands are flagged
  expect_true(all(all_$n_Peptides_shared[all_$Protein == "PX"] > 0))
  expect_true(all(all_$n_Peptides_shared[all_$Protein == "P2"] == 0))
})

test_that("expand_mapped_proteins uses the engine's own column and separator", {
  # DIA-NN: ';' inside Accession
  diann <- expand_mapped_proteins(make_diann_pep_all())
  expect_true("PX" %in% diann$ProteinFirst)
  expect_equal(sum(diann$ProteinFirst == "PX"), 4L)   # AAA + BBB, in 2 samples

  # FragPipe: ', ' inside Mapped_Proteins
  fp <- expand_mapped_proteins(make_fragpipe_pep_all())
  expect_true(all(c("PX", "PY") %in% fp$ProteinFirst))
  # the peptide with an empty Mapped_Proteins keeps its leading protein only
  expect_equal(sum(fp$ProteinFirst == "P2"), 2L)
  expect_true(all(fp$Protein_shared[fp$ProteinFirst == "PX"]))
  expect_false(any(fp$Protein_shared[fp$ProteinFirst == "P2"]))
})

test_that("expand_mapped_proteins warns and falls back with no mapped-protein list", {
  # PEAKS' peptide export and the custom-dictionary path carry no such list
  dat <- make_fragpipe_pep_all()
  dat$Mapped_Proteins <- ""

  expect_warning(out <- expand_mapped_proteins(dat), "no mapped-protein")
  expect_equal(nrow(out), nrow(dat))                 # nothing expanded
  expect_setequal(out$ProteinFirst, c("P1", "P2"))
  expect_false(any(out$Protein_shared))

  # and build_prot_all(multi_mapping = "all") degrades the same way
  expect_warning(res <- build_prot_all(dat, multi_mapping = "all"), "no mapped-protein")
  expect_setequal(res$Protein, c("P1", "P2"))
})

test_that("unique-peptide counts come from whichever flag the engine provides", {
  # DIA-NN: Proteotypic == 1
  diann <- build_prot_all(make_diann_pep_all())
  expect_equal(diann$n_Peptides_unique[diann$Protein == "P1" & diann$Sample == "S1"], 1L)
  expect_equal(diann$n_Peptides_unique[diann$Protein == "P2" & diann$Sample == "S1"], 2L)

  # FragPipe: Is_Unique == "Y"
  fp <- build_prot_all(make_fragpipe_pep_all())
  expect_equal(fp$n_Peptides_unique[fp$Protein == "P1" & fp$Sample == "S1"], 0L)
  expect_equal(fp$n_Peptides_unique[fp$Protein == "P2" & fp$Sample == "S1"], 1L)

  # neither flag present (PEAKS, custom) -> NA, not a wrong zero
  bare <- make_fragpipe_pep_all()
  bare$Is_Unique <- NULL
  expect_true(all(is.na(build_prot_all(bare)$n_Peptides_unique)))
})

test_that("prot_engine_columns finds engine-reported protein values", {
  diann <- prot_engine_columns(make_diann_pep_all())
  expect_equal(diann$quantity, "PG.MaxLFQ")
  expect_equal(diann$qvalue, "PG.Q.Value")

  # FragPipe reports annotation but no protein quantity
  fp <- prot_engine_columns(make_fragpipe_pep_all())
  expect_equal(fp$quantity, character(0))
  expect_equal(fp$qvalue, character(0))
  expect_true("Mapped_Proteins" %in% fp$annotation)

  # both DIA-NN naming generations are recognised
  newer <- make_diann_pep_all()
  names(newer)[names(newer) == "PG.MaxLFQ"] <- "PG.Abundance"
  expect_equal(prot_engine_columns(newer)$quantity, "PG.Abundance")
  expect_true(all(c("PG.Quantity", "PG.Abundance") %in% diann_protein_columns()))
})

test_that("engine values are carried when constant and NA'd when they vary", {
  dat <- make_diann_pep_all()

  # grouped at the scope DIA-NN computed them for: carried through unchanged
  by_protein <- build_prot_all(dat, protein = "ProteinFirst")
  expect_equal(by_protein$PG.MaxLFQ[by_protein$Protein == "P1"], c(100, 100))
  expect_equal(by_protein$PG.Q.Value[by_protein$Protein == "P2"], c(0.02, 0.02))
  expect_null(attr(by_protein, "engine_columns_varied"))

  # grouped coarser than that scope: two protein groups, two different PG values
  # -> NA rather than an average or a silently-picked first value
  by_gene <- build_prot_all(dat, protein = "GeneFirst")
  expect_true(all(is.na(by_gene$PG.MaxLFQ)))
  expect_false(any(by_gene$PG.MaxLFQ %in% c(100, 200, 150)))
  varied <- attr(by_gene, "engine_columns_varied")
  expect_equal(unname(varied[["PG.MaxLFQ"]]), 2)     # both samples affected

  # and they can be switched off entirely
  expect_false("PG.MaxLFQ" %in% names(build_prot_all(dat, engine_columns = FALSE)))
})

test_that("summarise_prot_all and top_source_proteins condense the table", {
  prot_all <- build_prot_all(make_diann_pep_all())

  summ <- summarise_prot_all(prot_all, by = "Condition")
  expect_equal(nrow(summ), 4L)                       # 2 proteins x 2 Conditions
  expect_true(all(summ$n_Samples_detected == 1))     # one sample per Condition here
  expect_true(all(c("n_Peptides_mean", "n_Peptides_total", "Area_total") %in% names(summ)))

  top <- top_source_proteins(prot_all, n = 10)
  expect_equal(top$n_Peptides, c(4, 4))              # pooled over both samples -- a tie
  expect_equal(top$n_Samples, c(2, 2))
  expect_equal(sum(top$Area), sum(prot_all$Area))    # nothing lost in the pooling

  # ranking by Area puts the higher-intensity protein first, and the filter bites
  expect_equal(top_source_proteins(prot_all, by = "Area")$Protein[1], "P2")
  expect_equal(nrow(top_source_proteins(prot_all, min_peptides = 99)), 0L)
})

test_that("build_prot_all degrades on empty and malformed input", {
  dat <- make_diann_pep_all()

  empty <- build_prot_all(dat[0, , drop = FALSE])
  expect_equal(nrow(empty), 0L)
  expect_true(all(c("Protein", "n_Peptides", "Area", "Log2Area") %in% names(empty)))

  # rows with no protein assigned are dropped, not counted as a "" protein
  blank <- dat
  blank$ProteinFirst[1:2] <- ""
  expect_false("" %in% build_prot_all(blank)$Protein)

  expect_error(build_prot_all(dat[, setdiff(names(dat), "Sequence")]),
               "missing column")
  expect_error(build_prot_all(dat, protein = "NotAColumn"))
})
