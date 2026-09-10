# Helpers shared by the report templates (R/report-helpers.R). These used to be
# copy-pasted expressions inside the skeletons, which is how the MHC windows
# ended up defined in four places and how a single-Condition subset could abort
# every report through combn(conditions, 2).

test_that("mhc_length_window knows the built-in classes and falls back to custom bounds", {
  expect_equal(mhc_length_window("MHC1"), c(8L, 13L))
  expect_equal(mhc_length_window("MHC1_mouse"), c(7L, 11L))
  expect_equal(mhc_length_window("MHC2"), c(12L, 25L))
  expect_equal(mhc_length_window(), c(8L, 13L))

  # unrecognised class -> the ShortPeptideLengthMin/Max params take over
  expect_equal(mhc_length_window("custom", min = 9, max = 11), c(9L, 11L))
  # ... and without them there is nothing to fall back to but MHC1, with a warning
  expect_warning(w <- mhc_length_window("custom"), "unknown MHCclass")
  expect_equal(w, c(8L, 13L))
})

test_that("mhc_class_palette gives MHC2 its own colours and mouse the MHC1 ones", {
  expect_length(mhc_class_palette("MHC1"), 2)
  expect_equal(mhc_class_palette("MHC1_mouse"), mhc_class_palette("MHC1"))
  expect_false(identical(mhc_class_palette("MHC2"), mhc_class_palette("MHC1")))
  expect_equal(mhc_class_palette("nonsense"), mhc_class_palette("MHC1"))
  expect_true(all(grepl("^#[0-9a-fA-F]{6}$", mhc_class_palette("MHC2"))))
})

test_that("mhc_classes lists exactly the classes the two lookups know", {
  for (cls in mhc_classes()) {
    expect_length(mhc_length_window(cls), 2)
    expect_length(mhc_class_palette(cls), 2)
  }
})

test_that("condition_pairs matches combn but survives a single Condition", {
  three <- c("CTRL", "TREAT", "OTHER")
  pairs <- condition_pairs(three)
  expect_length(pairs, 3L)
  expect_equal(unname(pairs), utils::combn(three, 2, simplify = FALSE))
  expect_equal(names(pairs), c("CTRL_vs_TREAT", "CTRL_vs_OTHER", "TREAT_vs_OTHER"))

  # the regression: combn(x, 2) errors with n < m, this must not
  expect_equal(condition_pairs("CTRL"), list())
  expect_equal(condition_pairs(character(0)), list())

  # factor input keeps the annotation order, not the alphabetical one
  f <- factor(c("TREAT", "CTRL"), levels = c("TREAT", "CTRL"))
  expect_equal(unname(condition_pairs(f)[[1]]), c("TREAT", "CTRL"))
})

test_that("condition_pairs(self = TRUE) appends the self-comparisons", {
  out <- condition_pairs(c("A", "B"), self = TRUE)
  expect_equal(names(out), c("A_vs_B", "A_vs_A", "B_vs_B"))

  # single Condition: the overlap matrix still gets its one diagonal cell
  one <- condition_pairs("A", self = TRUE)
  expect_equal(names(one), "A_vs_A")
  expect_equal(one[[1]], c("A", "A"))
})

# provider_line() (v0.17.0): the report header attribution used to be a hardcoded
# organisation in every skeleton, which branded every rendered report of a
# distributable package to one platform. It is now the optional `Provider` param.

test_that("provider_line names the provider when one is given", {
  expect_equal(provider_line("My Lab"), "Provided by My Lab.")
  expect_equal(provider_line("Immunopeptidomics Platform (IPP)"),
               "Provided by Immunopeptidomics Platform (IPP).")
  # surrounding whitespace should not leak into the sentence
  expect_equal(provider_line("  My Lab  "), "Provided by My Lab.")
})

test_that("provider_line falls back to a generic sentence naming no organisation", {
  generic <- "Generated with the HowMaHiCo R package."

  expect_equal(provider_line(""), generic)          # the param default
  expect_equal(provider_line(), generic)
  expect_equal(provider_line("   "), generic)       # whitespace only
  expect_equal(provider_line(NA), generic)
  expect_equal(provider_line(NA_character_), generic)
  expect_equal(provider_line(NULL), generic)        # rmarkdown drops YAML-null params
  expect_equal(provider_line(character(0)), generic)

  # a report must never be attributed to someone who did not produce it
  expect_false(grepl("Provided by", generic, fixed = TRUE))
})

test_that("provider_line always returns a single string", {
  for (x in list("Lab", "", NA, NULL, c("A", "B"))) {
    out <- provider_line(x)
    expect_type(out, "character")
    expect_length(out, 1L)
  }
})
