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

test_that("read_annot errors when Sample_fp/Sample_peaks or the minimal identity columns are missing", {
  no_sample_col <- data.frame(Condition = "JY", BioReplicate = "JY_1", TechReplicate = "1", Sample = "JY_1")
  csv1 <- tempfile(fileext = ".csv")
  write.csv(no_sample_col, csv1, row.names = FALSE)
  expect_error(read_annot(csv1), "Sample_peaks or Sample_fp")

  no_condition_col <- data.frame(BioReplicate = "JY_1", TechReplicate = "1", Sample = "JY_1", Sample_fp = "JY_1")
  csv2 <- tempfile(fileext = ".csv")
  write.csv(no_condition_col, csv2, row.names = FALSE)
  expect_error(read_annot(csv2), "must contain all the following columns")
})
