#' Extract tables from double column pdf documents in a folder
#'
#' Tables will be extracted from all pdf files in a directory, using the
#' extractor_tables function.
#'
#' @param directory The directory containing pdfs from which tables will be extracted.
#' @param rec TRUE/FALSE indicating whether the table in the pdf or the page has
#'    a rectangular dimension.That is, all rows and all columns are of equal length
#'    this is important because reading a table without proper dimension will
#'    through an error.
#' @param full_names TRUE/FALSE indicating if the full file path should be used.
#'    Default is TRUE, see \code{\link{list.files}} for more details.
#' @param file_pattern An optional regular expression to select specific file
#'    names. Only files that match the regular expression will be searched.
#'    Defaults to all pdfs, i.e. \code{".pdf"}. See \code{\link{list.files}}
#'    for more details.
#'    Default is FALSE, see \code{\link{list.files}} for more details.
#' @param delimiter A delimiter used to detect tables. The default is two
#'   consecutive blank white spaces.
#' @param delimiter_table A delimiter used to separate table cells. The default
#'   value is two consecutive blank white spaces.
#' @param replacement A delimiter used to separate table cells after the
#'   replacement of white space is done.
#' @return A list containing data.frame for all extracted table
#' @export
directory_tables2 <- function(directory,
                             rec = FALSE,
                             file_pattern= ".pdf",
                             full_names = TRUE,
                             delimiter = "\\s{2,}",
                             delimiter_table = "\\s{2,}",
                             replacement = "|"){

  files_dir <- list.files(path = directory, pattern = file_pattern,
                          full.names = full_names)

  file_name <- list.files(path = directory, pattern = file_pattern,
                          full.names = FALSE)

  tabless <- lapply(seq_along(files_dir), function(xx)
    extractor_tables2(files_dir[[xx]], path = TRUE,
                     rec = rec,
                     delimiter = "\\s{2,}",
                     delimiter_table = "\\s{2,}",
                     replacement = "|"))

  names(tabless) <- file_name

  tabless
}

