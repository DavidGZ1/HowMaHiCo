# translate_ptm() has to cope with THREE token dialects, because the PTM column
# is written differently by every engine: DIA-NN stores UniMod accessions,
# FragPipe a delta mass in parentheses behind a position+residue prefix, PEAKS a
# signed delta mass in brackets rounded to two decimals. A UniMod-only
# translation would be a silent no-op on the project's default (FragPipe) data.

test_that("UniMod accessions translate", {
  expect_equal(translate_ptm("(UniMod:35)"), "Oxidation")
  expect_equal(translate_ptm("(UniMod:4)"), "Carbamidomethyl")
  expect_equal(translate_ptm("(unimod: 21)"), "Phospho")   # case/space tolerant
})

test_that("FragPipe and PEAKS delta masses translate", {
  expect_equal(translate_ptm("2M(15.9949)"), "Oxidation")       # FragPipe
  expect_equal(translate_ptm("N-term(42.0106)"), "Acetyl")      # FragPipe, n-term
  expect_equal(translate_ptm("[+15.99]"), "Oxidation")          # PEAKS, 2 decimals
  expect_equal(translate_ptm("[-17.03]"), "Gln->pyro-Glu")      # negative delta
  expect_equal(translate_ptm("C(57.0215)"), "Carbamidomethyl")
})

test_that("the tolerance still separates near-neighbour masses", {
  # Acetyl 42.010565 vs Trimethyl 42.046950 differ by 0.036 Da
  expect_equal(translate_ptm("(42.0106)"), "Acetyl")
  expect_equal(translate_ptm("(42.0470)"), "Trimethyl")
})

test_that("unrecognised tokens, NA and empty strings pass through unchanged", {
  expect_equal(translate_ptm("(UniMod:9999)"), "(UniMod:9999)")
  expect_equal(translate_ptm("(999.1234)"), "(999.1234)")
  expect_equal(translate_ptm("something"), "something")
  expect_equal(translate_ptm(""), "")
  expect_equal(translate_ptm(NA_character_), NA_character_)
  expect_equal(translate_ptm(character(0)), character(0))
})

test_that("translate_ptm is vectorised and order-preserving", {
  x <- c("2M(15.9949)", NA, "(UniMod:1)", "2M(15.9949)", "zzz")
  expect_equal(translate_ptm(x),
               c("Oxidation", NA, "Acetyl", "Oxidation", "zzz"))
})

test_that("row order of the reference decides mass-degenerate collisions", {
  # -18.010565 is both Glu->pyro-Glu (27) and Dehydrated (23); the reference is
  # ordered by commonness, so the first match wins and a reordered copy flips it
  expect_equal(translate_ptm("(-18.0106)"), "Glu->pyro-Glu")
  ref <- ptm_reference()
  flipped <- rbind(ref[ref$name == "Dehydrated", ], ref[ref$name != "Dehydrated", ])
  expect_equal(translate_ptm("(-18.0106)", reference = flipped), "Dehydrated")
})

test_that("ptm_reference is a well-formed lookup table", {
  ref <- ptm_reference()
  expect_named(ref, c("accession", "name", "mono_mass"))
  expect_true(is.integer(ref$accession))
  expect_true(is.numeric(ref$mono_mass))
  expect_false(any(duplicated(ref$accession)))
  expect_false(any(duplicated(ref$name)))
})

test_that("plot_ptm_heatmap translates its tile labels", {
  pep <- data.frame(
    Condition = factor(rep(c("CTRL", "TREAT"), each = 2)),
    Peptide   = c("SLFIGLKEV", "GLFDSLKEA", "SLFIGLKEV", "ALWGFFPVL"),
    Sequence  = c("SLFIGLKEV", "GLFDSLKEA", "SLFIGLKEV", "ALWGFFPVL"),
    Accession = c("P1", "P2", "P1", "P3"),
    Area      = c(10, 20, 30, 40),
    PTM       = c("2M(15.9949)", "(UniMod:35)", "1C(57.0215)", ""),
    stringsAsFactors = FALSE
  )

  p_translated <- plot_ptm_heatmap(pep, type = "count")
  expect_s3_class(p_translated, "ggplot")
  # both engines' spelling of oxidation collapses onto one row
  expect_true(all(c("Oxidation", "Carbamidomethyl") %in% p_translated$data$PTM))

  p_raw <- plot_ptm_heatmap(pep, type = "count", translate = FALSE)
  expect_false(any(c("Oxidation", "Carbamidomethyl") %in% p_raw$data$PTM))
})
