# Guard (v0.16.1): pkgdown aborts its whole site build when an exported function
# is missing from the _pkgdown.yml reference index ("N topics missing from
# index"). devtools::check() does not look at _pkgdown.yml at all, and the
# pkgdown workflow only runs on master, so three release cycles (v0.9.0-v0.13.0)
# each added exports without indexing them and the failure only surfaced after
# the merge to master -- leaving the published site stuck at v0.8.0.
#
# This catches the same mistake in the ordinary test suite instead.
#
# _pkgdown.yml is .Rbuildignore'd, so it is not inside the installed/built
# package: it is found by walking up from the test directory to the repo root.
# When that fails (an installed-package test run with no source tree nearby) the
# test skips rather than failing for the wrong reason.

find_repo_file <- function(filename, max_up = 6) {
  dir <- normalizePath(testthat::test_path("."), winslash = "/", mustWork = FALSE)
  for (i in seq_len(max_up)) {
    candidate <- file.path(dir, filename)
    if (file.exists(candidate)) return(candidate)
    parent <- dirname(dir)
    if (identical(parent, dir)) break
    dir <- parent
  }
  NA_character_
}

# pkgdown lets a section list tidyselect-style helpers instead of bare topic
# names; those are not literal topics, so they are dropped before comparing.
pkgdown_index_topics <- function(path) {
  cfg <- yaml::read_yaml(path)
  topics <- unlist(lapply(cfg$reference, function(section) section$contents))
  topics <- trimws(as.character(topics))
  topics[!grepl("^(starts_with|ends_with|matches|contains|has_keyword|has_concept|lacks_concepts|everything)\\(",
                topics)]
}

test_that("every exported function appears in the _pkgdown.yml reference index", {
  skip_if_not_installed("yaml")
  pkgdown_yml <- find_repo_file("_pkgdown.yml")
  skip_if(is.na(pkgdown_yml), "_pkgdown.yml not found (not a source checkout)")

  topics <- pkgdown_index_topics(pkgdown_yml)
  exports <- sort(getNamespaceExports("HowMaHiCo"))

  missing <- setdiff(exports, topics)
  expect_equal(
    missing, character(0),
    info = paste0(
      "These exports are missing from _pkgdown.yml and will abort the pkgdown ",
      "site build:\n  ", paste(missing, collapse = ", "),
      "\nAdd them to a `- title:` section's `contents:`, or mark them ",
      "@keywords internal."))
})

test_that("the _pkgdown.yml reference index has no stale or duplicated entries", {
  skip_if_not_installed("yaml")
  pkgdown_yml <- find_repo_file("_pkgdown.yml")
  skip_if(is.na(pkgdown_yml), "_pkgdown.yml not found (not a source checkout)")

  topics <- pkgdown_index_topics(pkgdown_yml)
  exports <- getNamespaceExports("HowMaHiCo")

  # A renamed or removed function left behind in the index aborts the build too.
  # The package-level doc topic is an Rd alias, not an export, so it is allowed.
  stale <- setdiff(topics, c(exports, "HowMaHiCo-package"))
  expect_equal(
    stale, character(0),
    info = paste0("These _pkgdown.yml entries do not name an exported ",
                  "function:\n  ", paste(stale, collapse = ", ")))

  # Listing a topic twice puts it on the reference page twice.
  duplicated_topics <- unique(topics[duplicated(topics)])
  expect_equal(
    duplicated_topics, character(0),
    info = paste0("These topics are listed more than once in _pkgdown.yml:\n  ",
                  paste(duplicated_topics, collapse = ", ")))
})
