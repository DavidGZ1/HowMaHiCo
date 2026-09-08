test_that("read_annot validates required columns, normalizes Sample_peaks, strips Source_file extensions, and orders factors by appearance", {
  annot_df <- data.frame(
    Condition = c("JY-tissue", "JY-tissue", "JY plasma"),
    BioReplicate = c("JY_1", "JY_2", "JY_3"),
    TechReplicate = c("1", "1", "1"),
    Sample = c("JY_1", "JY_2", "JY_3"),
    Sample_fp = c("JY_1", "JY_2", "JY_3"),
    Sample_peaks = c("JY_1", "JY_2", "JY_3"),
    Source_file = c("run1.d", "run2.raw", "run3"),
    stringsAsFactors = FALSE
  )
  csv_path <- tempfile(fileext = ".csv")
  write.csv(annot_df, csv_path, row.names = FALSE)

  annot <- read_annot(csv_path)

  expect_s3_class(annot$Condition, "factor")
  expect_equal(levels(annot$Condition), c("JY-tissue", "JY plasma"))
  expect_equal(as.character(annot$Source_file), c("run1", "run2", "run3"))
})

test_that("read_annot replaces hyphens/spaces in Sample_peaks with underscores and warns", {
  annot_df <- data.frame(
    Condition = "JY", BioReplicate = "JY_1", TechReplicate = "1", Sample = "JY_1",
    Sample_peaks = "JY-1", stringsAsFactors = FALSE
  )
  csv_hyphen <- tempfile(fileext = ".csv")
  write.csv(annot_df, csv_hyphen, row.names = FALSE)
  expect_warning(annot1 <- read_annot(csv_hyphen), "Hyphens")
  expect_equal(as.character(annot1$Sample_peaks), "JY_1")

  annot_df$Sample_peaks <- "JY 1"
  csv_space <- tempfile(fileext = ".csv")
  write.csv(annot_df, csv_space, row.names = FALSE)
  expect_warning(annot2 <- read_annot(csv_space), "Spaces")
  expect_equal(as.character(annot2$Sample_peaks), "JY_1")
})

test_that("read_annot errors when no folder column or a minimal identity column is missing", {
  no_sample_col <- data.frame(Condition = "JY", BioReplicate = "JY_1", TechReplicate = "1", Sample = "JY_1")
  csv1 <- tempfile(fileext = ".csv")
  write.csv(no_sample_col, csv1, row.names = FALSE)
  expect_error(read_annot(csv1), "Sample_folder")

  no_condition_col <- data.frame(BioReplicate = "JY_1", TechReplicate = "1", Sample = "JY_1", Sample_fp = "JY_1")
  csv2 <- tempfile(fileext = ".csv")
  write.csv(no_condition_col, csv2, row.names = FALSE)
  expect_error(read_annot(csv2), "must contain all the following columns")
})

# ---- unified annotation schema (Sample_folder) ------------------------------

test_that("read_annot accepts the canonical Sample_folder and derives the loader aliases", {
  df <- data.frame(Condition = "JY", BioReplicate = "JY_1", TechReplicate = "1",
                   Sample = "JY_1", Sample_folder = "JY-run 1")
  csv <- tempfile(fileext = ".csv")
  write.csv(df, csv, row.names = FALSE)

  # both PEAKS normalizations fire on this value, so both warnings are expected
  expect_warning(expect_warning(annot <- read_annot(csv), "Hyphens"), "Spaces")
  # canonical column is untouched, the PEAKS alias gets PEAKS' own normalization
  expect_equal(as.character(annot$Sample_folder), "JY-run 1")
  expect_equal(as.character(annot$Sample_fp), "JY-run 1")
  expect_equal(as.character(annot$Sample_peaks), "JY_run_1")
})

test_that("read_annot still loads legacy Sample_fp / Sample_peaks tables", {
  fp <- data.frame(Condition = "JY", BioReplicate = "JY_1", TechReplicate = "1",
                   Sample = "JY_1", Sample_fp = "JY_1")
  csv <- tempfile(fileext = ".csv")
  write.csv(fp, csv, row.names = FALSE)
  annot <- read_annot(csv)
  expect_equal(as.character(annot$Sample_folder), "JY_1")
  expect_equal(as.character(annot$Sample_fp), "JY_1")

  # an explicitly supplied alias is never overwritten by the derived one
  both <- data.frame(Condition = "JY", BioReplicate = "JY_1", TechReplicate = "1",
                     Sample = "JY_1", Sample_folder = "JY_1", Sample_peaks = "OTHER")
  csv2 <- tempfile(fileext = ".csv")
  write.csv(both, csv2, row.names = FALSE)
  annot2 <- read_annot(csv2)
  expect_equal(as.character(annot2$Sample_peaks), "OTHER")
})

test_that("get_annot_peaks indexes a PEAKS export into a skeleton annotation", {
  out <- get_annot_peaks(test_path("fixtures", "peaks_export"))

  expect_true(all(c("Sample_folder", "File_peaks_nb", "Condition", "BioReplicate",
                    "TechReplicate", "Sample", "Sample_ID") %in% names(out)))
  expect_true("JY_PEAKS_01" %in% out$Sample_folder)
  expect_true(all(out$Condition == ""))
})

# ---- get_annot_sampleid safeguards ------------------------------------------

# Minimal HyStar-style sample list: Result.Path + Sample.Comment, one row per run.
write_sample_list <- function(runs, comments = paste0(runs, "_ID")) {
  f <- tempfile(fileext = ".xlsx")
  openxlsx::write.xlsx(
    data.frame(Result.Path = paste0("D:/data/", runs, ".d"), Sample.Comment = comments),
    f)
  f
}

test_that("get_annot_sampleid warns when nothing matched the sample list", {
  annot <- make_annot()
  xlsx <- write_sample_list(c("nothing_like_it_1", "nothing_like_it_2"))

  expect_warning(out <- get_annot_sampleid(annot, xlsx), "no Source_file matched")
  expect_equal(nrow(out), 0L)

  expect_warning(out_all <- get_annot_sampleid(annot, xlsx, keep_all = TRUE), "no Source_file matched")
  expect_equal(nrow(out_all), nrow(annot))
  expect_true(all(is.na(out_all$Sample_ID)))
})

test_that("get_annot_sampleid warns about partially matched rows and keep_all keeps them", {
  annot <- make_annot()
  runs <- as.character(annot$Source_file)
  xlsx <- write_sample_list(runs[-1])                    # first annotation row unmatched

  expect_warning(out <- get_annot_sampleid(annot, xlsx), "had no match")
  expect_equal(nrow(out), nrow(annot) - 1L)

  expect_warning(out_all <- get_annot_sampleid(annot, xlsx, keep_all = TRUE), "had no match")
  expect_equal(nrow(out_all), nrow(annot))
  expect_equal(sum(is.na(out_all$Sample_ID)), 1L)
})

test_that("get_annot_sampleid is silent and fills every Sample_ID on a full match", {
  annot <- make_annot()
  runs <- as.character(annot$Source_file)
  xlsx <- write_sample_list(runs)

  expect_silent(out <- get_annot_sampleid(annot, xlsx))
  expect_equal(nrow(out), nrow(annot))
  expect_equal(out$Sample_ID, paste0(runs, "_ID"))
})
