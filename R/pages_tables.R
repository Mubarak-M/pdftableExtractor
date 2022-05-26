#' Extract tables from pdf documents
#'
#' Using the pdftools package, tables in the pdf document are extracted
#' as a dataframe and returned as a list.
#'
#' @param x Either the text of the pdf read in with the pdftools package or a
#'    path for the location of the pdf file.
#' @param pages Numeric vector of pages from which table will be extracted.
#'     it can be a single number or a vector of numbers.
#' @param path TRUE/FALSE; An optional path designation for the location of the pdf to be
#'    converted to text. The pdftools package is used for this conversion.
#' @param rec TRUE/FALSE indicating whether the table in the pdf or the page has
#'    a rectangular dimension.That is, all rows and all columns are of equal length.
#'    This is important because reading a table without proper dimension will
#'    produce an error.
#' @param onecol TRUE/FALSE indicating whether the pdf file is one column
#' @param delimiter A delimiter used to detect tables. The default is two
#'   consecutive blank white spaces.
#' @param delimiter_table A delimiter used to separate table cells. The default
#'   value is two consecutive blank white spaces.
#' @param replacement A delimiter used to separate table cells after the
#'   replacement of white space is done.
#' @return A list containing data.frame for all extracted table
#' @examples
#' file <- system.file("extdata", "onecoldata.pdf", package = "pdftableExtractor")
#'
#' table2 <- pages_tables(file,pages = 19, path = TRUE)
#' table2
#'
#' # extract rectangular data
#' pages_tables(file, pages = 19, path = TRUE, rec = TRUE)
#'
#' @export
pages_tables <- function(x, pages, path = FALSE,
                        rec = FALSE,
                        onecol = FALSE,
                        delimiter = "\\s{2,}",
                        delimiter_table = "\\s{2,}",
                        replacement = "|") {

  if(path) {
    x <- pdftools::pdf_text(x)
    #Turns the pdf to character vectors, number of vectors equals number of pages in the PDF file
  }
  x <- x[pages]
  tables <- lapply(seq_along(x), function(ii)
    extractor_tables(x[[ii]], path = FALSE,
                      rec = rec,
                      onecol=onecol,
                      delimiter = "\\s{2,}",
                      delimiter_table = "\\s{2,}",
                      replacement = "|"))
  tables
}
