% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/extractor_tables.R
\name{find_table_locations}
\alias{find_table_locations}
\title{Find table locations}
\usage{
find_table_locations(row_numbers)
}
\arguments{
\item{row_numbers}{Row numbers of PDF text that are possible table locations.}
}
\description{
From input of row numbers of possible table locations, this function detects
 subsequent row numbers to identify single tables.
}
