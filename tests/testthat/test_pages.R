test_that('number of page extracted', {
  file <- system.file("extdata", "twocoldata.pdf", package = "pdftableExtractor")

  tab2 <- pages_tables(file, path = TRUE, pages = 3)

  expect_equal(length(tab2), 1)
})


