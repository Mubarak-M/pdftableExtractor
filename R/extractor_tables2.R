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
      x_lines <- unlist(stringi::stri_split_lines(x))
      x_lines <- gsub("^\\s+|\\s+$", '', x_lines)
      x_lines <- gsub("\002", '-', x_lines)## correctly represent minus sign
    }

    possible_table_locations <- grep("\\s{2,}|\\s{2,}$", x_lines)##recent
    ##posibble location of the find table location function

    table_locations <- find_table_locations(possible_table_locations, x_lines)

    table_locations <- lapply(table_locations, table_location_sequence)
    #full table locations without omited lines, if any exist previously

    table_text_space <- lapply(seq_along(table_locations), function(xx)
      x_lines[table_locations[[xx]]]) #extract the lines from the original x_lines using the known table locations
    #add delimiter function should be here

    table_text_delim <- lapply(table_text_space, add_delimiter,
                               delimiter = delimiter_table,
                               replacement = replacement)
    #replace white spaces between table text with /

    if(rec){
      tables <- lapply(table_text_delim, rec_table)

      #tables <- lapply(seq_along(table_text_delim), function(xx)
         #rec_table(table_text_delim[[xx]])
        #)

      #tables <- lapply(seq_along(table_text_delim), function(xx){
      # output_con <- textConnection(table_text_delim[[xx]])
      #data_table <- read.csv(output_con, sep = "/")
      #data_table
      #})
      tables
    }else{
      tables <- lapply(table_text_space, as.data.frame, use.names=TRUE)
      #tables <- lapply(seq_along(tables), function(xx)
      #tables[[xx]][-1,])
      tables
  }
}


find_table_locations <- function(possible_table_locations, x_lines) {

  characters_line_split <-unlist(lapply(seq_len(length(possible_table_locations)), function(xx)
    length(strsplit(x_lines[possible_table_locations[[xx]]], "\\s{2,}")[[1]])))


  characters_line_split_Adj <- characters_line_split>2

  #rlee <- rle(characters_line_split_Adj)

  #characters_line_split_Adj <- rlee$lenghts>2

  rle_df_character <- data.frame(
    lengths = rle(characters_line_split_Adj)$lengths,
    values = rle(characters_line_split_Adj)$values)

  rle_df_character$select <- ifelse(rle_df_character$lengths > 2 & rle_df_character$values, 1, 0)

  rle_df_character$start <- c(1, cumsum(rle_df_character$lengths[1:(nrow(rle_df_character)-1)]) + 1)
  rle_df_character$end <- cumsum(rle_df_character$lengths)
  rle_df_character$new_values <- ifelse(rle_df_character$select, TRUE, FALSE)
  rle_df_true <- rle_df_character[rle_df_character$new_values == TRUE, ]

  convert_to_true <- lapply(1:nrow(rle_df_true), function(xx)
      rle_df_true[xx, 'start']:rle_df_true[xx, 'end']
    )

  row_numbers_return <- lapply(seq_along(convert_to_true), function(xx)
      possible_table_locations[convert_to_true[[xx]]]
      ## create the original indices of the true runs in the x_lines output
    )

    row_numbers_return

}

add_delimiter <- function(table_lines, delimiter = "\\s{2,}",
                          replacement = "|") {

  gsub(delimiter, replacement, table_lines)

}

table_location_sequence <- function(row_numbers_return){
  loc_sequence <- min(row_numbers_return):max(row_numbers_return)
  loc_sequence
}

## function for clean rectangular table
rec_table <- function(table_text){
  output_con <- textConnection(table_text)
  data_table <- read.csv(output_con, sep = "|")
  data_table <- data.frame(data_table)
  data_table
}
