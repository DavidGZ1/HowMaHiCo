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
