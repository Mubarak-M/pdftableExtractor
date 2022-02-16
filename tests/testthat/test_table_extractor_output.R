test_that('number of table extracted not less than table in pdf', {
  file <- system.file("extdata", "onecoldata.pdf", package = "pdftableExtractor")

  table1 <- extractor_tables(file, path = TRUE)

  expect_true(length(table1)>= 9)
})


