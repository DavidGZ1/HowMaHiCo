test_that("select_unique selects columns then drops duplicate rows and unused factor levels", {
  pep_all <- make_pep_all()
  out <- select_unique(pep_all, Condition, Sequence)

  expect_equal(names(out), c("Condition", "Sequence"))
  expect_equal(nrow(out), nrow(unique(pep_all[, c("Condition", "Sequence")])))
  expect_true(is.factor(out$Condition))
  expect_setequal(levels(out$Condition), as.character(unique(out$Condition)))
})

test_that("filter_unique filters rows then drops duplicates and unused factor levels", {
  pep_all <- make_pep_all()
  out <- filter_unique(pep_all, Condition == "JY_tissue")

  expect_true(all(as.character(out$Condition) == "JY_tissue"))
  expect_equal(levels(out$Condition), "JY_tissue")
  expect_equal(nrow(out), nrow(unique(pep_all[pep_all$Condition == "JY_tissue", ])))
})
