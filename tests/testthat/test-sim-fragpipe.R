# Tests against the simulated FragPipe dataset shipped in inst/extdata
# (sim_fragpipe_dda: 2 Conditions x 3 BioReplicates, individual-mode psm.tsv;
# generated with MaHiCoInSilico). Unlike the hand-synthesized loader fixtures,
# this is a realistically sized, multi-condition dataset, so it exercises the full
# build -> render path (correlation, %CV, UpSet, combn(conditions, 2) all valid).

sim_dir   <- system.file("extdata", "sim_fragpipe_dda", package = "HowMaHiCo")
sim_annot <- system.file("extdata", "sim_fragpipe_dda_annotation.csv", package = "HowMaHiCo")

test_that("build_pep_all on the simulated FragPipe data yields a valid 2-condition pep_all", {
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  annot <- read_annot(sim_annot)
  pep_all <- suppressWarnings(suppressMessages(
    build_pep_all("fragpipe_dda_individual", folder_data = sim_dir,
                  annotation = annot, shortpep_range = c(8, 13))))

  expect_silent(validate_pep_all(pep_all, "FragPipe"))
  expect_setequal(levels(pep_all$Condition), c("CTRL", "TREAT"))
  expect_equal(dplyr::n_distinct(pep_all$Sample), 6L)
  expect_gt(nrow(pep_all), 0)
})

test_that("a focused report renders end-to-end against the simulated data (PepAllSource = build)", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  # Copy the read-only extdata into a writable temp project so the build-mode
  # cache write (and outputs) land somewhere writable.
  proj <- tempfile("simproj_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)            # proj/sim_fragpipe_dda/<samples>
  file.copy(sim_annot, proj)                            # proj/sim_fragpipe_dda_annotation.csv

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "01_id_counts",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "",
        MHCclass            = "MHC1",
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = FALSE
      ),
      output_file = "sim_01_id_counts.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
  # build mode also wrote the pep_all cache it parsed
  expect_true(file.exists(file.path(proj, "sim_fragpipe_dda", "pep_all.rda")))
})

test_that("06_quant_stats renders end-to-end against the simulated data", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("limma")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("simquant_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "06_quant_stats",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "",
        MHCclass            = "MHC1",
        PeptideSet          = "selected",
        StatMethod          = "limma",
        NormMethod          = "median",
        ImputeMethod        = "none",
        PermutationTest     = TRUE,
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = FALSE
      ),
      output_file = "sim_06_quant_stats.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
  # the statistical results are part of the always-written export tier
  expect_true(file.exists(file.path(proj, "quant_stats_results.csv")))
  expect_true(file.exists(file.path(proj, "quant_stats_summary.csv")))

  summ <- utils::read.csv(file.path(proj, "quant_stats_summary.csv"))
  expect_equal(nrow(summ), 1L)             # one contrast: TREAT vs CTRL
  expect_gt(summ$n_tested, 0)
})

test_that("a single-Condition subset renders (combn(conditions, 2) regression)", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("simone_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  # keep only the CTRL samples -> one Condition, which used to abort every report
  # in the shared setup chunk with "n < m" from combn(conditions, 2)
  one_cond <- derive_filtered_annotation("sim_fragpipe_dda_annotation.csv", proj, "CTRL")
  expect_true(file.exists(one_cond))
  expect_equal(dplyr::n_distinct(read_annot(one_cond)$Condition), 1L)

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "02_overlaps",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = basename(one_cond),
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "ctrl",
        MHCclass            = "MHC1",
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = FALSE
      ),
      output_file = "sim_02_overlaps_one_condition.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
})

test_that("the mouse MHC-I window reaches a rendered report", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if(sim_dir == "" || sim_annot == "", "sim_fragpipe_dda extdata not installed")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  proj <- tempfile("simmouse_"); dir.create(proj)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  file.copy(sim_dir, proj, recursive = TRUE)
  file.copy(sim_annot, proj)

  out <- suppressWarnings(suppressMessages(
    run_howmahico_report(
      "01_id_counts",
      params = list(
        SampleSet           = "sim",
        Software            = "fragpipe_dda_individual",
        Instrument          = "tims_tof",
        FolderDocumentation = proj,
        AnnotationFile      = "sim_fragpipe_dda_annotation.csv",
        FolderData          = file.path(proj, "sim_fragpipe_dda"),
        FolderResults       = proj,
        FolderFigures       = proj,
        ProjectDir          = proj,
        PepAllSource        = "build",
        Subset              = "",
        MHCclass            = "MHC1_mouse",
        ResultsOverwrite    = TRUE,
        PlotsSave           = FALSE,
        CsvSave             = FALSE
      ),
      output_file = "sim_01_id_counts_mouse.html",
      quiet = TRUE)))

  expect_true(file.exists(out))
  html <- readLines(out, warn = FALSE)
  expect_true(any(grepl("7 to 11 AAs", html, fixed = TRUE)))   # the mouse window is in force
  expect_true(any(grepl("MHC1_mouse", html, fixed = TRUE)))    # ... and named in the title
})
