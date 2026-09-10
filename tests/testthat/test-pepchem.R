# Tests for the peptide-chemistry engine (R/pepchem.R). Like test-quality-score.R
# and test-quant-stats.R these work on small hand-built inputs: the point is the
# maths (composition, position resolution, effect sizes, the test scaffolding),
# not the search-engine parsing, which the loader tests already cover.

# 2 Conditions x 3 samples. TREAT is deliberately enriched in the hydrophobic
# residues, so GRAVY must separate the two Conditions while pI must not.
make_props_input <- function(seed = 42, n = 60) {
  set.seed(seed)
  aa <- c("A", "R", "N", "D", "C", "Q", "E", "G", "H", "I",
          "L", "K", "M", "F", "P", "S", "T", "W", "Y", "V")
  draw <- function(n, hydrophobic_weight) {
    replicate(n, paste(sample(aa, 9, replace = TRUE,
                              prob = ifelse(aa %in% c("I", "L", "V", "F"),
                                            hydrophobic_weight, 1)),
                       collapse = ""))
  }
  samples <- paste0(rep(c("CTRL", "TREAT"), each = 3), "_", 1:3)
  out <- do.call(rbind, lapply(samples, function(s) {
    cond <- sub("_.*", "", s)
    data.frame(Sample = s, BioReplicate = s, Condition = cond,
               Sequence = draw(n, if (cond == "TREAT") 6 else 1),
               stringsAsFactors = FALSE)
  }))
  out$Condition <- factor(out$Condition, levels = c("CTRL", "TREAT"))
  out$Sample <- factor(out$Sample, levels = samples)
  out
}

test_that("peptide_properties reproduces GRAVY and deduplicates sequences", {
  kd <- c(S = -0.8, I = 4.5, N = -3.5, F = 2.8, E = -3.5, K = -3.9, L = 3.8)
  expected <- mean(kd[strsplit("SIINFEKL", "")[[1]]])

  out <- peptide_properties(c("SIINFEKL", "GILGFVFTL", "SIINFEKL"))

  expect_equal(nrow(out), 2L)                       # the duplicate collapses
  expect_equal(out$GRAVY[out$Sequence == "SIINFEKL"], expected)
  expect_equal(out$GRAVY[out$Sequence == "SIINFEKL"], 0.4875)
  expect_equal(out$Length, nchar(out$Sequence))
  # class fractions are fractions of the standard residues
  expect_equal(out$frac_Aromatic[out$Sequence == "SIINFEKL"], 1 / 8)
  expect_true(all(out$frac_Polar >= 0 & out$frac_Polar <= 1))
})

test_that("peptide_properties survives empty input and non-standard residues", {
  empty <- peptide_properties(character(0))
  expect_equal(nrow(empty), 0L)
  expect_true(all(c("Sequence", "GRAVY", "pI", "frac_Basic") %in% names(empty)))
  expect_type(empty$Sequence, "character")

  # NA / "" are dropped rather than propagated
  expect_equal(nrow(peptide_properties(c("SIINFEKL", NA, ""))), 1L)

  # X is not one of the 20 standard residues: it must not break the fractions,
  # and it must raise exactly ONE warning, not one per Peptides descriptor
  expect_warning(out <- peptide_properties("SIXNFEKL"), "non-standard residues")
  expect_equal(nrow(out), 1L)
  expect_false(is.na(out$frac_Polar))
  # the fractions are over the 7 standard residues, not the 8 characters
  expect_equal(out$frac_Aromatic, 1 / 7)

  # a clean set stays warning-free
  expect_silent(peptide_properties(c("SIINFEKL", "GILGFVFTL")))
})

test_that("aa_composition frequencies sum to one within each group", {
  comp <- aa_composition(c("SIINFEKL", "GILGFVFTL"), groups = c("A", "B"))

  expect_equal(nlevels(comp$AA), 20L)
  expect_equal(as.numeric(tapply(comp$Frequency, comp$Group, sum)), c(1, 1))
  expect_equal(sum(comp$Count), sum(nchar(c("SIINFEKL", "GILGFVFTL"))))
  expect_equal(levels(comp$Group), c("A", "B"))
  # counts are per group, not pooled
  expect_equal(comp$Count[comp$Group == "A" & comp$AA == "I"], 2L)
})

test_that("aa_position_frequency profiles a fixed length and resolves negatives", {
  seqs <- rep(c("SIINFEKL", "SIINFEKV"), 10)   # 20 x 8-mers

  freq <- aa_position_frequency(seqs, min_n = 5)

  expect_equal(attr(freq, "length"), 8L)       # modal length picked automatically
  expect_equal(sort(unique(freq$Position)), 1:8)
  # P1 is S in every sequence, P8 is L or V half the time each
  expect_equal(freq$Frequency[freq$Position == 1 & freq$AA == "S"], 1)
  expect_equal(freq$Frequency[freq$Position == 8 & freq$AA == "L"], 0.5)
  # frequencies sum to 1 at every position
  expect_true(all(abs(tapply(freq$Frequency, freq$Position, sum) - 1) < 1e-12))
})

test_that("aa_position_frequency mixes lengths when positions are given", {
  # a scalar position resolved against a vector of lengths must not collapse:
  # ifelse() returns the length of its *test*, which silently kept one peptide
  seqs <- c(rep("SIINFEKL", 10), rep("GILGFVFTLA", 10))

  freq <- aa_position_frequency(seqs, positions = c(1, -1), min_n = 5)

  expect_equal(sort(unique(freq$Position)), c(-1L, 1L))
  expect_true(all(freq$n_Sequences == 20))
  # N-terminus: half S (from the 8-mers), half G (from the 10-mers)
  expect_equal(freq$Frequency[freq$Position == 1 & freq$AA == "S"], 0.5)
  expect_equal(freq$Frequency[freq$Position == 1 & freq$AA == "G"], 0.5)
  # C-terminus: L from the 8-mers, A from the 10-mers
  expect_equal(freq$Frequency[freq$Position == -1 & freq$AA == "L"], 0.5)
  expect_equal(freq$Frequency[freq$Position == -1 & freq$AA == "A"], 0.5)
})

test_that("aa_position_frequency drops groups below min_n and empty input", {
  freq <- aa_position_frequency(rep("SIINFEKL", 12),
                                groups = rep(c("big", "small"), c(11, 1)),
                                min_n = 10)
  expect_equal(unique(as.character(freq$Group)), "big")

  expect_equal(nrow(aa_position_frequency(character(0))), 0L)
  expect_equal(nrow(aa_position_frequency(rep("SIINFEKL", 3), min_n = 10)), 0L)
})

test_that(".resolve_positions recycles both arguments", {
  # scalar position, vector of lengths (the mixed-length branch)
  expect_equal(HowMaHiCo:::.resolve_positions(-1, c(8, 10, 12)), c(8, 10, 12))
  # vector of positions, scalar length (what anchor_information_content passes)
  expect_equal(HowMaHiCo:::.resolve_positions(c(2, -1), 9), c(2, 9))
  expect_equal(HowMaHiCo:::.resolve_positions(c(1, 2), c(9, 9)), c(1, 2))
})

test_that("cliffs_delta hits its anchors", {
  expect_equal(cliffs_delta(1:10, 1:10), 0)
  expect_equal(cliffs_delta(11:20, 1:10), 1)
  expect_equal(cliffs_delta(1:10, 11:20), -1)
  expect_true(is.na(cliffs_delta(numeric(0), 1:10)))
  expect_true(is.na(cliffs_delta(c(NA_real_, NA_real_), 1:10)))
  # bounded, and antisymmetric
  d <- cliffs_delta(c(1, 5, 9), c(2, 6, 10))
  expect_true(d >= -1 && d <= 1)
  expect_equal(d, -cliffs_delta(c(2, 6, 10), c(1, 5, 9)))
})

test_that("pepchem_by_sample keeps one row per sample-sequence pair", {
  input <- make_props_input(n = 20)
  # the same peptide seen twice in one sample (two charge states) collapses
  input <- rbind(input, input[1, ])

  props <- pepchem_by_sample(input)

  expect_equal(nrow(props), nrow(unique(input[, c("Sample", "Sequence")])))
  expect_true(all(c("Sample", "BioReplicate", "Condition", "Sequence",
                    "GRAVY", "pI") %in% names(props)))
  expect_false(anyNA(props$GRAVY))

  expect_error(pepchem_by_sample(data.frame(Sequence = "SIINFEKL")),
               "missing column")
})

test_that("summarise_pepchem and aggregate_pepchem chain into a sample summary", {
  props <- pepchem_by_sample(make_props_input(n = 20))

  ss <- summarise_pepchem(props, by = "Sample", properties = c("GRAVY", "pI"))
  expect_equal(nrow(ss), 6L * 2L)                  # 6 samples x 2 descriptors
  expect_true(all(c("Sample", "Condition", "Property", "N", "Mean",
                    "Median", "SD") %in% names(ss)))
  expect_equal(sort(unique(ss$N)), 20L)

  ag <- aggregate_pepchem(ss, stat = "Median")
  expect_equal(nrow(ag), 2L * 2L)                  # 2 Conditions x 2 descriptors
  expect_equal(sort(unique(ag$n_Samples)), 3L)
  # the aggregated mean is the mean of the per-sample medians, not of the peptides
  gravy_ctrl <- ss$Median[ss$Property == "GRAVY" & ss$Condition == "CTRL"]
  expect_equal(ag$Mean[ag$Property == "GRAVY" & ag$Condition == "CTRL"],
               mean(gravy_ctrl))
})

test_that("compare_pepchem separates the planted hydrophobicity difference", {
  props <- pepchem_by_sample(make_props_input(n = 60))

  res <- compare_pepchem(props, level = "peptide",
                         properties = c("GRAVY", "pI"))

  expect_true(all(c("Property", "Level", "Contrast", "MedianDiff",
                    "CliffsDelta", "p_adj", "Significant") %in% names(res)))
  expect_equal(unique(res$Contrast), "TREAT_vs_CTRL")
  gravy <- res[res$Property == "GRAVY", ]
  expect_gt(gravy$MedianDiff, 0)       # TREAT is the hydrophobic one
  expect_gt(gravy$CliffsDelta, 0.5)
  expect_true(gravy$Significant)

  # the sample-level track sees the same direction, with n = 3 vs 3
  res_s <- compare_pepchem(props, level = "sample", properties = c("GRAVY", "pI"))
  expect_equal(res_s$Level[1], "sample")
  expect_equal(res_s$n1[res_s$Property == "GRAVY"], 3L)
  expect_gt(res_s$CliffsDelta[res_s$Property == "GRAVY"], 0)

  # the overall Kruskal-Wallis table rides along as an attribute
  kw <- attr(res_s, "kruskal")
  expect_equal(nrow(kw), 2L)
  expect_true(all(c("Property", "Statistic", "p_value", "p_adj") %in% names(kw)))
})

test_that("compare_pepchem degrades to an empty typed frame on one Condition", {
  props <- pepchem_by_sample(make_props_input(n = 20))
  one <- props[props$Condition == "CTRL", ]
  one$Condition <- droplevels(one$Condition)

  res <- compare_pepchem(one, properties = c("GRAVY", "pI"))

  expect_equal(nrow(res), 0L)
  expect_true(all(c("Property", "Level", "Contrast", "CliffsDelta",
                    "p_adj", "Significant") %in% names(res)))
  expect_equal(nrow(attr(res, "kruskal")), 0L)

  expect_error(compare_pepchem(one[, setdiff(names(one), "Condition")]),
               "no 'Condition' column")
})

test_that("compare_aa_frequency tests per-sample frequencies and reports a ratio", {
  props <- pepchem_by_sample(make_props_input(n = 60))

  res <- compare_aa_frequency(props)

  expect_equal(nrow(res), 20L)                     # one row per residue, one pair
  expect_true(all(c("AA", "Log2Ratio", "CliffsDelta", "p_adj") %in% names(res)))
  # n1/n2 are SAMPLE counts, not residue counts: the whole point of the design
  expect_equal(unique(c(res$n1, res$n2)), 3L)
  # the planted enrichment shows up in the hydrophobic residues
  expect_gt(res$Log2Ratio[res$AA == "L"], 0)
  expect_lt(res$Log2Ratio[res$AA == "D"], 0)
})

test_that("pepchem_properties exposes the two PropertySet choices", {
  core <- pepchem_properties("core")
  ext <- pepchem_properties("extended")

  expect_equal(core, c("Length", "GRAVY", "pI", "Charge"))
  expect_true(all(core %in% ext))
  expect_true(any(grepl("^frac_", ext)))
  # every advertised column really exists on the descriptor table
  expect_true(all(ext %in% names(peptide_properties("SIINFEKL"))))
  expect_error(pepchem_properties("nope"))
})
