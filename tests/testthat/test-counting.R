test_that("count_ids counts distinct peptides/sequences/proteins", {
  pep_all <- make_pep_all()
  out <- count_ids(pep_all)

  expect_equal(names(out), c("n_Peptides", "n_Sequences", "n_Proteins"))
  expect_equal(out$n_Peptides, dplyr::n_distinct(pep_all$Peptide))
  expect_equal(out$n_Sequences, dplyr::n_distinct(pep_all$Sequence))
  expect_equal(out$n_Proteins, dplyr::n_distinct(pep_all$Accession))
})

test_that("count_ids respects grouping", {
  pep_all <- make_pep_all()
  out <- pep_all %>% dplyr::group_by(Condition) %>% count_ids()

  expect_equal(nrow(out), dplyr::n_distinct(pep_all$Condition))
  expect_true(all(c("Condition", "n_Peptides", "n_Sequences", "n_Proteins") %in% names(out)))
})

test_that("count_ids_condition_bylengthrange computes per-Condition x Length_range proportions/cumulatives that sum to 1 at the All-peptides level", {
  pep_all <- make_pep_all()
  out <- count_ids_condition_bylengthrange(pep_all)

  expect_true(all(c("Condition", "Length_range", "Level", "Count", "Proportion",
                    "Percentage", "CumProportion", "CumCount") %in% names(out)))
  expect_true("All peptides" %in% levels(out$Length_range))

  all_rows <- out[out$Length_range == "All peptides", ]
  expect_true(all(all_rows$Proportion == 1))
})

test_that("get_charge_group classifies numeric charges into +1/+2/>=+3 factor levels", {
  pep_all <- make_pep_all()
  out <- get_charge_group(pep_all)

  expect_true(is.numeric(out$Charge))
  expect_equal(levels(out$Charge_group), c("+ 1", "+ 2", "≥ +3"))
  expect_equal(unique(as.character(out$Charge_group[out$Charge == 1])), "+ 1")
  expect_equal(unique(as.character(out$Charge_group[out$Charge == 2])), "+ 2")
  expect_equal(unique(as.character(out$Charge_group[out$Charge == 3])), "≥ +3")
})

test_that("get_proportion_charge derives proportions of each charge group relative to its Total row", {
  count_table <- make_count_charge_table()
  out <- get_proportion_charge(count_table)

  expect_true(all(c("Level", "Count", "Proportion", "Percentage", "CumProportion") %in% names(out)))
  totals <- out[out$Charge_group == "Total", ]
  expect_true(all(totals$Proportion == 1))
})

test_that("count_ids_by pivots per-sample peptide counts wide, one n_Samples.<Condition> column per condition", {
  pep_all <- make_pep_all()
  out <- count_ids_by(pep_all, Condition)

  expect_true(all(c("Accession", "ProteinFirst", "GeneFirst", "Length", "Peptide", "Sequence") %in% names(out)))
  expect_true(all(grepl("^n_Samples\\.", grep("^n_Samples", names(out), value = TRUE))))
  expect_setequal(sub("^n_Samples\\.", "", grep("^n_Samples", names(out), value = TRUE)),
                  levels(pep_all$Condition))
})

test_that("summarise_area computes per-group Area mean/sd/CV with CV_perc = CV * 100", {
  pep_all <- make_pep_all()
  out <- summarise_area(pep_all, Condition)

  expect_true(all(c("Count", "Area_mean", "Area_sd", "Area_CV", "Area_CV_perc") %in% names(out)))
  expect_equal(out$Area_CV_perc, out$Area_CV * 100)
})

test_that("list_sequences returns one non-empty character vector per group level", {
  pep_all <- make_pep_all()
  out <- list_sequences(pep_all, "Condition")

  expect_type(out, "list")
  expect_setequal(names(out), levels(pep_all$Condition))
  expect_true(all(vapply(out, is.character, logical(1))))
})

test_that("get_mat_log2area builds a numeric matrix with columns ordered by the col factor's levels", {
  pep_all <- make_pep_all()
  mat <- get_mat_log2area(pep_all, PeptideID, Sample)

  expect_true(is.matrix(mat))
  expect_true(is.numeric(mat))
  expect_equal(colnames(mat), levels(pep_all$Sample))
})

test_that("check_ids_global classifies decoy/contaminant/assigned rows and adds Total proportions", {
  pep_all <- make_pep_all()
  out <- check_ids_global(pep_all)

  expect_setequal(out$ProteinType, c("Decoy", "Contaminant", "Assigned to Protein", "Total"))
  expect_true(all(c("prop_Peptides", "prop_Sequences", "prop_Proteins") %in% names(out)))

  total_row <- out[out$ProteinType == "Total", ]
  expect_equal(total_row$prop_Peptides, 1)
  expect_equal(total_row$n_Peptides, dplyr::n_distinct(pep_all$Peptide))
})

test_that("get_mat_log2area survives a dataset where every Area is zero", {
  # compute_log2area() maps Area == 0 to NA, so every ID becomes a "phantom" and
  # the pivot has no columns left; this used to abort the report's data chunk
  # with "Elements `JY_1`... don't exist" before any plot-level guard could fire.
  pep_all <- make_pep_all()
  pep_all$Area <- 0
  pep_all$Log2Area <- NA_real_

  expect_warning(mat <- get_mat_log2area(pep_all, PeptideID, Sample), "no non-missing Log2Area")
  expect_true(is.matrix(mat))
  expect_equal(nrow(mat), 0L)
  expect_equal(colnames(mat), levels(pep_all$Sample))
  expect_true(is.numeric(mat))

  # the normal path is untouched
  mat_ok <- get_mat_log2area(make_pep_all(), PeptideID, Sample)
  expect_gt(nrow(mat_ok), 0)
  expect_equal(colnames(mat_ok), levels(make_pep_all()$Sample))
})
