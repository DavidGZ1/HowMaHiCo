test_that("read_peaks pivots per-sample columns into long format with derived core columns", {
  out <- read_peaks(test_path("fixtures", "peaks_export"), "JY_PEAKS_01", instrument = "tims_tof")

  expect_true(all(c("Sequence", "Charge", "Nter", "Cter", "Sample_peaks", "Area",
                    "invk0_start", "invk0_end", "invk0", "Score") %in% names(out)))

  # 4 peptide rows x 2 samples, long-pivoted on Area#<sample>
  expect_equal(nrow(out), 8)
  expect_setequal(unique(out$Sample_peaks), c("JY_1", "JY_2"))

  # Score is renamed from the mangled `-10lgP` column
  expect_equal(sort(unique(out$Score)), sort(unique(c(35.2, 33.1, 40.5, 38.0))))

  # Sequence strips the parenthesised modification annotation from Peptide
  expect_true("AAAVAAAAL" %in% out$Sequence)
  expect_false(any(grepl("\\(", out$Sequence)))

  # Charge is derived as round(Mass / m_z)
  expect_equal(as.character(unique(out$Charge)), "+ 2")
})

test_that("read_peaks parses tims_tof ion mobility into invk0_start/end/mid", {
  out <- read_peaks(test_path("fixtures", "peaks_export"), "JY_PEAKS_01", instrument = "tims_tof")
  row <- out[out$Sequence == "GILGFVFTL" & out$Sample_peaks == "JY_1", ]

  expect_equal(row$invk0_start, 0.80)
  expect_equal(row$invk0_end, 0.90)
  expect_equal(row$invk0, (0.80 + 0.90) / 2)
})

test_that("read_peaks keeps explicit zero-area rows (only true NAs are dropped by the pivot)", {
  out <- read_peaks(test_path("fixtures", "peaks_export"), "JY_PEAKS_01", instrument = "tims_tof")

  # NLVPMVATV's Area#JY_2 = 0 is read as numeric 0 (not NA), so values_drop_na
  # keeps it -- 4 peptides x 2 samples = 8 rows survive the long pivot intact
  expect_equal(nrow(out), 8)
  expect_true(any(out$Sequence == "NLVPMVATV" & out$Sample_peaks == "JY_2" & out$Area == 0))
})

test_that("parse_peaks derives pep_all core columns from raw PEAKS data", {
  raw <- read_peaks(test_path("fixtures", "peaks_export"), "JY_PEAKS_01", instrument = "tims_tof")
  out <- parse_peaks(raw, shortpep_range = c(8, 13))

  expect_true(all(c("Accession", "Peptide", "Sequence", "Length", "Score",
                    "Area", "Log2Area", "Length_range", "Charge", "Nter", "Cter",
                    "ProteinFirst", "GeneFirst", "OrganismFirst", "PeptideID",
                    "Found_By", "Sample_peaks") %in% names(out)))

  expect_equal(unique(out$Found_By), "PEAKS")

  # all fixture peptides are length 9 → within 8-13 AAs window
  expect_true(all(as.character(out$Length_range) == "8 to 13 AAs"))

  # sp|P11111|AAA1_HUMAN → pipe→underscore → sp_P11111_AAA1_HUMAN
  # separate(sep="_", into=c("ProteinFirst","GeneFirst","OrganismFirst"), extra="drop")
  # takes the first three pieces: "sp", "P11111", "AAA1"
  expect_true("sp" %in% out$ProteinFirst)
  expect_true("P11111" %in% out$GeneFirst)
  expect_true("AAA1" %in% out$OrganismFirst)
})

test_that("parse_peaks maps zero Area to NA Log2Area", {
  raw <- read_peaks(test_path("fixtures", "peaks_export"), "JY_PEAKS_01", instrument = "tims_tof")
  out <- parse_peaks(raw)

  zero_row <- out[out$Sequence == "NLVPMVATV" & out$Sample_peaks == "JY_2", ]
  expect_equal(zero_row$Area, 0)
  expect_true(is.na(zero_row$Log2Area))
})

test_that("annotate_peaks joins parsed PEAKS results to the annotation table by Sample_peaks", {
  raw <- read_peaks(test_path("fixtures", "peaks_export"), "JY_PEAKS_01", instrument = "tims_tof")
  parsed <- parse_peaks(raw)
  annot <- make_annot()[make_annot()$Sample_peaks %in% c("JY_1", "JY_2"), ]

  out <- suppressMessages(annotate_peaks(parsed, annot))

  expect_equal(nrow(out), 8)
  expect_true(all(c("Condition", "BioReplicate", "TechReplicate", "Sample", "Sample_ID") %in% names(out)))
  expect_setequal(unique(as.character(out$Sample_peaks)), c("JY_1", "JY_2"))
})

test_that("annotate_peaks requires the minimal annotation columns", {
  raw <- read_peaks(test_path("fixtures", "peaks_export"), "JY_PEAKS_01", instrument = "tims_tof")
  parsed <- parse_peaks(raw)
  bad_annot <- make_annot()[, setdiff(names(make_annot()), "Condition")]

  expect_error(annotate_peaks(parsed, bad_annot), "missing from the annotation table")
})

# End-to-end tests against the simulated PEAKS Xpro export shipped in inst/extdata
# (sim_peaks_xpro: ONE export folder holding all 6 samples as Area#<sample>
# columns, which is the normal PEAKS layout). Until v0.22.0 the annotation-driven
# PEAKS path could not work at all: read_peaks_batch() filtered the export
# FOLDERS by annotation$Sample_peaks, which is the PER-SAMPLE key, so an
# annotation that could be joined by annotate_peaks() matched no folder (empty
# read -> "object 'Accession' not found" inside parse_peaks()), while an
# annotation naming the folder produced a silent 0-row join.

sim_peaks_dir   <- system.file("extdata", "sim_peaks_xpro", package = "HowMaHiCo")
sim_peaks_annot <- system.file("extdata", "sim_peaks_xpro_annotation.csv",
                               package = "HowMaHiCo")

test_that("build_pep_all('peaks_xpro') yields a valid pep_all from one multi-sample export", {
  skip_if(sim_peaks_dir == "" || sim_peaks_annot == "", "sim_peaks_xpro extdata not installed")

  annot <- read_annot(sim_peaks_annot)
  # the two keys really are different here, which is the whole point
  expect_equal(unique(as.character(annot$Sample_folder)), "sim_PEAKS_01")
  expect_gt(dplyr::n_distinct(annot$Sample_peaks), 1)

  pep_all <- suppressWarnings(suppressMessages(
    build_pep_all("peaks_xpro", folder_data = sim_peaks_dir, annotation = annot,
                  shortpep_range = c(8, 13), instrument = "tims_tof")))

  expect_silent(validate_pep_all(pep_all, "PEAKS"))
  expect_setequal(levels(droplevels(factor(pep_all$Condition))), c("CTRL", "TREAT"))
  expect_equal(dplyr::n_distinct(pep_all$Sample), 6L)
  expect_equal(unique(pep_all$Found_By), "PEAKS")
  # 1/k0 Range -> invk0 midpoint, and the long pivot kept every sample
  expect_true(all(is.finite(pep_all$invk0)))
  expect_equal(nrow(pep_all) %% 6L, 0L)
})

test_that("read_peaks_batch selects export folders by Sample_folder, not by sample", {
  skip_if(sim_peaks_dir == "", "sim_peaks_xpro extdata not installed")
  annot <- read_annot(sim_peaks_annot)

  raw <- suppressMessages(read_peaks_batch(folder = sim_peaks_dir, annotation = annot,
                                           instrument = "tims_tof"))
  expect_gt(nrow(raw), 0)
  # Sample_peaks in the DATA comes from the Area#<sample> column names
  expect_setequal(unique(raw$Sample_peaks), unique(as.character(annot$Sample_peaks)))
})

test_that("a folder/sample key mix-up fails loudly instead of silently", {
  skip_if(sim_peaks_dir == "", "sim_peaks_xpro extdata not installed")
  annot <- read_annot(sim_peaks_annot)

  # annotation naming a folder that is not on disk
  wrong_folder <- annot
  wrong_folder$Sample_folder <- "does_not_exist_PEAKS_09"
  expect_error(suppressMessages(read_peaks_batch(folder = sim_peaks_dir,
                                                 annotation = wrong_folder)),
               "No PEAKS export folder")

  # right folder, but the per-sample key does not match the Area# suffixes
  wrong_sample <- annot
  wrong_sample$Sample_peaks <- paste0("not_", wrong_sample$Sample_peaks)
  raw <- suppressMessages(read_peaks_batch(folder = sim_peaks_dir, annotation = wrong_sample,
                                           instrument = "tims_tof")) |>
    parse_peaks(shortpep_range = c(8, 13))
  expect_error(annotate_peaks(raw, wrong_sample), "No Sample_peaks value is shared")
})
