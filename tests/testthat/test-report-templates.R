# Regression guard (v0.7.1): a fenced r-chunk written inside the shared
# setup.Rmd HTML comment is still parsed by knitr (chunk headers are detected even
# inside comments, and leading whitespace is allowed). Such an example fence
# re-includes setup.Rmd and duplicates the 'setup' chunk label, aborting every
# focused report at parse time with "Duplicate chunk label 'setup'". Keep the
# leading comment free of chunk fences.

test_that("shared setup.Rmd has no chunk fence inside its leading HTML comment", {
  setup_rmd <- system.file("rmarkdown", "shared", "setup.Rmd", package = "HowMaHiCo")
  expect_true(nzchar(setup_rmd) && file.exists(setup_rmd))
  lines <- readLines(setup_rmd)

  comment_open  <- grep("<!--", lines)[1]
  comment_close <- grep("-->", lines)[1]
  expect_false(is.na(comment_open))
  expect_false(is.na(comment_close))

  in_comment <- lines[comment_open:comment_close]
  # knitr's chunk-begin pattern (leading tabs/spaces/">" allowed)
  chunk_begin <- "^[\t >]*```+\\s*\\{[rR][ ,}]"
  expect_false(any(grepl(chunk_begin, in_comment)))

  # exactly one real 'setup'-labelled chunk in the whole fragment
  expect_equal(sum(grepl("^[\t >]*```+\\s*\\{[rR][ ,]*setup[ ,}]", lines)), 1L)
})
