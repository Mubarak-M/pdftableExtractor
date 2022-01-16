#' Extract tables from pdf documents
#'
#' Using the pdftools package, tables in the loaded pdf document are extracted
#' as a dataframe and returned in a listt..
#'
#' @param x Either the text of the pdf read in with the pdftools package or a
#'    path for the location of the pdf file.
#' @param path An optional path designation for the location of the pdf to be
#'    converted to text. The pdftools package is used for this conversion.
#' @param rec TRUE/FALSE indicating whether the table in the pdf or the page has
#'    a rectangular dimension.That is, all rows and all columns are of equal length
#'    this is important because reading a table without proper dimension will
#'    through an error.
#' @param delimiter A delimiter used to detect tables. The default is two
#'   consecutive blank white spaces.
#' @param delimiter_table A delimiter used to separate table cells. The default
#'   value is two consecutive blank white spaces.
#' @param replacement A delimiter used to separate table cells after the
#'   replacement of white space is done.
#' @importFrom pdftools pdf_text
#' @importFrom tokenizers tokenize_lines
#' @importFrom stringi stri_split
#' @importFrom utils read.csv
#' @return A list containing data.frame for all extracted table
#' @example
#' file <- system.file("extdata", "twocoldata.pdf", package = "pdftableExtractor")
#'
#' table4 <- extractor_tables2(file, path = TRUE)
#' @export
extractor_tables2 <- function(x, path = FALSE, rec = FALSE,
                           delimiter = "\\s{2,}",
                           delimiter_table = "\\s{2,}",
                           replacement = "|") {

  if(path) {
    x <- pdftools::pdf_text(x)
  }
  line_nums <- cumsum(lapply(tokenizers::tokenize_lines(x), length))
  if(any(line_nums == 0)) {
    warning('text not recognized in pdf')
    text_out <- data.frame(keyword = NULL,
                           page_num = NULL,
                           line_num = NULL,
                           line_text = NULL)
  } else {
      x_liness <- unlist(stringi::stri_split_lines(x))
      x_liness <- gsub("^\\s+|\\s+$", '', x_liness)
      x_liness <- gsub("\002", '-', x_liness)## correctly represent minus sign
    }

    possible_table_locationsss <- grep("\\s{2,}|\\s{2,}$", x_liness)##recent
    ##posibble location of the find table location function

    table_locationss <- find_table_locationss(possible_table_locationsss, x_liness)

    table_locationss <- lapply(table_locationss, table_location_sequences)
    #full table locations without omited lines, if any exist previously

    table_text_spaces <- lapply(seq_along(table_locationss), function(xx)
      x_liness[table_locationss[[xx]]]) #extract the lines from the original x_liness using the known table locations
    #add delimiter function should be here

    table_text_delims <- lapply(table_text_spaces, add_delimiter,
                               delimiter = delimiter_table,
                               replacement = replacement)
    #replace white spaces between table text with /

    if(rec){
      tabless <- lapply(table_text_delims, rec_tables)

      #tables <- lapply(seq_along(table_text_delims), function(xx)
         #rec_tables(table_text_delims[[xx]])
        #)

      #tables <- lapply(seq_along(table_text_delims), function(xx){
      # output_con <- textConnection(table_text_delims[[xx]])
      #data_table <- read.csv(output_con, sep = "/")
      #data_table
      #})
      tabless
    }else{
      tabless <- lapply(table_text_spaces, as.data.frame, use.names=TRUE)
      #tables <- lapply(seq_along(tables), function(xx)
      #tables[[xx]][-1,])
      tabless
  }
}


find_table_locationss <- function(possible_table_locationsss, x_liness) {

  characters_line_split <-unlist(lapply(seq_len(length(possible_table_locationsss)), function(xx)
    length(strsplit(x_liness[possible_table_locationsss[[xx]]], "\\s{2,}")[[1]])))


  characters_line_split_Adj <- characters_line_split>2

  #rlee <- rle(characters_line_split_Adj)

  #characters_line_split_Adj <- rlee$lenghts>2

  rle_df_characters <- data.frame(
    lengths = rle(characters_line_split_Adj)$lengths,
    values = rle(characters_line_split_Adj)$values)

  rle_df_characters$select <- ifelse(rle_df_characters$lengths > 2 & rle_df_characters$values, 1, 0)

  rle_df_characters$start <- c(1, cumsum(rle_df_characters$lengths[1:(nrow(rle_df_characters)-1)]) + 1)
  rle_df_characters$end <- cumsum(rle_df_characters$lengths)
  rle_df_characters$new_values <- ifelse(rle_df_characters$select, TRUE, FALSE)
  rle_df_trues <- rle_df_characters[rle_df_characters$new_values == TRUE, ]

  convert_to_trues <- lapply(1:nrow(rle_df_trues), function(xx)
      rle_df_trues[xx, 'start']:rle_df_trues[xx, 'end']
    )

  row_numbers_returns <- lapply(seq_along(convert_to_trues), function(xx)
      possible_table_locationsss[convert_to_trues[[xx]]]
      ## create the original indices of the true runs in the x_liness output
    )

    row_numbers_returns

}

add_delimiter <- function(table_lines, delimiter = "\\s{2,}",
                          replacement = "|") {

  gsub(delimiter, replacement, table_lines)

}

table_location_sequences <- function(row_numbers_returns){
  loc_sequences <- min(row_numbers_returns):max(row_numbers_returns)
  loc_sequences
}

## function for clean rectangular table
rec_tables <- function(table_text){
  output_con <- textConnection(table_text)
  data_table <- read.csv(output_con, sep = "|")
  data_table <- data.frame(data_table)
  data_table
}
