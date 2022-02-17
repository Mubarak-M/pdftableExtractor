test_that('exttract two pages', {
  file <- system.file("extdata", "twocoldata.pdf", package = "pdftableExtractor")

  tab2 <- pages_tables(file, path = TRUE, pages = c(3,4))

  expect_equal(length(tab2), 2)
})
