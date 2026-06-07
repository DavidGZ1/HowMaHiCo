test_that("count_intersect/count_merged count distinct shared and combined values across two conditions", {
  pep_all <- make_pep_all() %>% as.data.frame()

  jy_seqs <- unique(pep_all$Sequence[pep_all$Condition == "JY_tissue"])
  plasma_seqs <- unique(pep_all$Sequence[pep_all$Condition == "JY_plasma"])

  expect_equal(count_intersect(pep_all, "Sequence", "JY_tissue", "JY_plasma"),
               dplyr::n_distinct(intersect(jy_seqs, plasma_seqs)))
  expect_equal(count_merged(pep_all, "Sequence", "JY_tissue", "JY_plasma"),
               dplyr::n_distinct(c(jy_seqs, plasma_seqs)))

  # AAAVAAAAL is shared between JY_tissue and JY_plasma in the fixture
  expect_true(count_intersect(pep_all, "Sequence", "JY_tissue", "JY_plasma") >= 1)
})

test_that("count_uniqueby counts distinct entries per group, with an optional Total row", {
  pep_all <- make_pep_all()

  out <- count_uniqueby(pep_all, vars = Sample, by = Condition)
  expect_equal(names(out), c("Condition", "n_Sample"))
  expect_equal(nrow(out), dplyr::n_distinct(pep_all$Condition))

  out_total <- count_uniqueby(pep_all, vars = Sample, by = Condition, total = TRUE)
  expect_true("Total" %in% as.character(out_total$Condition))
  total_row <- out_total[out_total$Condition == "Total", ]
  expect_equal(total_row$n_Sample, dplyr::n_distinct(pep_all$Sample))
})

test_that("count_uniqueby_ip pivots sample/patient counts wide by group, one n_<var>s.<level> column per group level", {
  pep_all <- make_pep_all()
  out <- count_uniqueby_ip(pep_all, var = Sample, by = Condition, level = "Peptide")

  expect_true(all(c("Accession", "ProteinFirst", "GeneFirst", "OrganismFirst",
                    "Length", "Peptide", "Sequence") %in% names(out)))
  expect_setequal(sub("^n_Samples\\.", "", grep("^n_Samples", names(out), value = TRUE)),
                  levels(pep_all$Condition))

  out_protein <- count_uniqueby_ip(pep_all, var = Sample, by = Condition, level = "Protein")
  expect_true(all(c("Accession", "ProteinFirst", "GeneFirst", "OrganismFirst") %in% names(out_protein)))
  expect_false("Length" %in% names(out_protein))
})

test_that("count_samples_patients column-binds the five per-Patient/Sample_type/Condition summaries", {
  pep_all <- make_pep_all()
  out <- count_samples_patients(pep_all, level = "Peptide")

  key_columns <- c("Accession", "ProteinFirst", "GeneFirst", "OrganismFirst", "Length", "Peptide", "Sequence")
  expect_true(all(key_columns %in% names(out)))
  expect_true(sum(grepl("^n_", names(out))) > 5)
  expect_equal(nrow(out), nrow(unique(pep_all[, key_columns])))
})
