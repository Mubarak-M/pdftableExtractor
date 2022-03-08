test_that('page out of range', {
  file <- system.file("extdata", "twocoldata.pdf", package = "pdftableExtractor")

  expect_error(pages_tables(file, path = TRUE, pages = 7))

})

library(tidyverse)
data <- diamonds
summarise(data, average = mean(price))

summarise(data, mean(price))

arrange(data, desc(price), carat)
arrange(data, desc(price), desc(carat))

x <- arrange(data, desc(price))
x[1:20,]

y <- mutate(congress_age,
       total = n(),
       prop_democrat = mean(age)
)

library(fivethirtyeight)
str(congress_age)
y
select(y, bioguide:lastname)
select(y, lastname:freetime)
