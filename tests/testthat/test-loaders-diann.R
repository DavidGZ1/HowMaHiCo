test_that("read_diann_batch discovers every report.tsv and derives Sample_fp from the parent folder", {
  out <- read_diann_batch(test_path("fixtures", "diann"))

  # see test-loaders-fragpipe.R for why only the basename is stable here
  expect_setequal(basename(unique(out$Sample_fp)), c("run1", "run2"))
  expect_equal(nrow(out), 5)
  expect_true(all(c("File.Name", "Run", "Protein.Group", "Stripped.Sequence", "Precursor.Charge") %in% names(out)))
})

test_that("parse_diann reshapes raw report rows into pep_all schema", {
  raw <- make_diann_report_raw()
  out <- parse_diann(raw, shortpep_range = c(8, 13))

  expect_equal(nrow(out), 3)
  expect_true(all(c("Sample_fp", "Accession", "Peptide", "Sequence", "Length", "Score",
                    "Area", "Log2Area", "Length_range", "PTM", "Charge", "Nter", "Cter",
                    "RT", "invk0", "Mass", "ppm", "m_z", "Source_file", "Source_File_ID",
                    "Precursor_Id", "Found_By", "PeptideID") %in% names(out)))

  expect_equal(out$Found_By, rep("DIA-NN", 3))
  expect_equal(as.character(out$Charge), rep("+ 2", 3))
  expect_equal(out$Length, nchar(raw$Stripped.Sequence))
  expect_equal(as.character(out$Length_range), c("8 to 13 AAs", "8 to 13 AAs", "8 to 13 AAs"))

  # ppm is a hardcoded dummy; Mass is computed from Precursor.Mz/Precursor.Charge
  expect_equal(out$ppm, rep(0, 3))
  expect_equal(out$Mass, (raw$Precursor.Mz - 1.007276) * raw$Precursor.Charge)

  # Source_file is extracted from the Windows-style File.Name path
  expect_equal(out$Source_file, rep("run1", 3))
})

test_that("parse_diann maps zero-area rows to NA Log2Area", {
  raw <- make_diann_report_raw()
  out <- parse_diann(raw)
  zero_row <- out[out$Area == 0, ]

  expect_equal(nrow(zero_row), 1)
  expect_true(is.na(zero_row$Log2Area))
})

test_that("annotate_diann joins parsed DIA-NN results to the annotation table by Sample_fp + Source_file", {
  parsed <- parse_diann(make_diann_report_raw(samplename = "JY_1"))
  annot <- make_annot()
  annot$Source_file <- factor(ifelse(annot$Sample_fp == "JY_1", "run1", as.character(annot$Source_file)))

  out <- suppressWarnings(suppressMessages(annotate_diann(parsed, annot)))

  expect_equal(nrow(out), 3)
  expect_true(all(c("Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_ID") %in% names(out)))
  expect_equal(unique(as.character(out$Sample)), "JY_1")
})

test_that("annotate_diann requires the minimal annotation columns", {
  parsed <- parse_diann(make_diann_report_raw())
  bad_annot <- make_annot()[, setdiff(names(make_annot()), "Condition")]

  expect_error(annotate_diann(parsed, bad_annot), "missing from the annotation table")
})

# Protein-column tolerance (v0.18.0): parse_diann()'s select() was a bare-name
# whitelist, so a report that lacked any one of ~45 columns aborted the parse, and
# a report using DIA-NN's newer protein-quantity names (PG.Abundance rather than
# PG.Quantity) had those columns silently dropped before reaching pep_all. The
# protein/gene-level names now go through dplyr::any_of(diann_protein_columns()).

test_that("parse_diann survives a report missing the optional protein-quant columns", {
  raw <- make_diann_report_raw()
  raw <- raw[, setdiff(names(raw), c("PG.Quantity", "PG.Normalised", "PG.MaxLFQ",
                                     "Genes.Quantity", "Genes.Normalised",
                                     "Genes.MaxLFQ", "Genes.MaxLFQ.Unique",
                                     "PG.Q.Value", "Global.PG.Q.Value",
                                     "GG.Q.Value"))]

  expect_no_error(out <- parse_diann(raw, shortpep_range = c(8, 13)))
  expect_equal(nrow(out), 3)
  # the core schema is untouched, the absent optional columns simply are not there
  expect_true(all(c("Accession", "ProteinFirst", "GeneFirst", "Area") %in% names(out)))
  expect_false("PG.MaxLFQ" %in% names(out))
  # Protein.Q.Value is still present and still carried
  expect_true("Protein.Q.Value" %in% names(out))
})

test_that("parse_diann keeps newer-generation DIA-NN protein-quantity names", {
  raw <- make_diann_report_raw()
  names(raw)[names(raw) == "PG.Quantity"]  <- "PG.Abundance"
  names(raw)[names(raw) == "PG.Normalised"] <- "PG.NormalisedAbundance"
  raw$PG.Abundance <- c(111, 222, 333)

  out <- parse_diann(raw, shortpep_range = c(8, 13))

  expect_true("PG.Abundance" %in% names(out))
  expect_true("PG.NormalisedAbundance" %in% names(out))
  expect_equal(out$PG.Abundance, c(111, 222, 333))
  # and the old spelling is gone rather than silently duplicated
  expect_false("PG.Quantity" %in% names(out))

  # the protein engine picks the new spelling up downstream, alongside whatever
  # other quantity columns the report happens to carry
  quant <- prot_engine_columns(out)$quantity
  expect_true(all(c("PG.Abundance", "PG.NormalisedAbundance") %in% quant))
  expect_false("PG.Quantity" %in% quant)
})
