test_that('page out of range', {
  file <- system.file("extdata", "twocoldata.pdf", package = "pdftableExtractor")

  expect_error(pages_tables(file, path = TRUE, pages = 7))

})
