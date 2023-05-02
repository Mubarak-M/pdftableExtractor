#' Extract tables from pdf documents
#'
#' Using the pdftools package, tables in the pdf document are extracted
#' as a dataframe and returned as a list.
#'
#' @param x Either the text of the pdf read in with the pdftools package or a
#'    path for the location of the pdf file.
#' @param path TRUE/FALSE; An optional path designation for the location of the pdf to be
#'    converted to text. The pdftools package is used for this conversion.
#' @param rec TRUE/FALSE indicating whether the table in the pdf or the page has
#'    a rectangular dimension. That is, all rows and all columns are of equal length.
#'    This is important because reading a table without proper dimension will
#'    produce an error.
#' @param onecol TRUE/FALSE indicating whether the pdf file is one column, used
#' only by the extract_pages helper function
#' @param delimiter A delimiter used to detect tables. The default is two
#'   consecutive blank white spaces.
#' @param delimiter_table A delimiter used to separate table cells. The default
#'   value is two consecutive blank white spaces.
#' @param replacement A delimiter used to separate table cells after the
#'   replacement of white space is done.
#' @importFrom pdftools pdf_text
#' @importFrom tokenizers tokenize_lines
#' @importFrom stringi stri_split stri_split_lines stri_split_regex stri_isempty
#' @importFrom utils read.csv
#' @examples
#' file <- system.file("extdata", "onecoldata.pdf", package = "pdftableExtractor")
#'
#' table1 <- extractor_tables(file, path = TRUE)
#' @return A list containing data.frame for all extracted table
#' @export
extractor_tables <- function(x, path = FALSE,
                              rec = FALSE,
                              onecol = FALSE,
                              delimiter = "\\s{2,}",
                              delimiter_table = "\\s{2,}",
                              replacement = "|") {

  if(path) {
    x <- pdftools::pdf_text(x)
    #Turns the pdf to character vectors, number of vectors equals number of pages in the PDF file
  }
  line_nums <- cumsum(lapply(tokenizers::tokenize_lines(x), length))
  #Breaks the giant character vectors representing pages into character vectors representing lines per page and sum number
  #of lines per page
  if(all(line_nums == 0)) {
    warning('text not recognized in pdf')

    #Checks if any page has cumulative sum of zero to determine if the text is a pdf file
  } else {
    x_lines <- unlist(stringi::stri_split_lines(x))
    x_lines <- gsub("^\\s+|\\s+$", '', x_lines)#remove all white spaces at the beginning of line or at the end of a line.
    x_lines <- gsub("\002", '-', x_lines)## correctly represent minus sign

  }

  if(onecol) {
    textcol = 1
  } else {
    textcol <- detect_num_textcolumns(x)
  }


  if(textcol == 1) {
    possible_table_locations <- grep(delimiter, x_lines)
    table_locations <- find_table_locations(possible_table_locations)
    #calls find_table_locations function and returns a list of possible number of table and indices of each line in the table in x_lines

  } else {
    possible_table_locations <- grep("\\s{2,}|\\s{2,}$", x_lines)
    table_locations <- find_table_locations_multicol(possible_table_locations, x_lines)
  }

  table_locations <- lapply(table_locations, table_location_sequence)
  #full table locations without ommited lines, if any exist previously

  table_text_space <- lapply(seq_along(table_locations), function(xx)
    x_lines[table_locations[[xx]]]) #extract the lines from the original x_lines using the known table locations
  #add delimiter function should be here

  table_text_delim <- lapply(table_text_space, add_delimiter,
                             delimiter = delimiter_table,
                             replacement = replacement)
  #replace white spaces between table text with /

  if(rec) {
    tables <- lapply(table_text_delim, rec_table)
    #tables <- lapply(seq_along(table_text_delim), function(xx){
    # output_con <- textConnection(table_text_delim[[xx]])
    #data_table <- read.csv(output_con, sep = "/")
    #data_table
    #})
    tables

  } else {

    tables <- lapply(table_text_space, as.data.frame, use.names=TRUE)
    #tables <- lapply(seq_along(tables), function(xx)
    #tables[[xx]][-1,])
    tables

  }


}

detect_num_textcolumns <- function(x, pattern = "\\p{WHITE_SPACE}{3,}") {

  x_lines <- stringi::stri_split_lines(x)

  x_lines <- lapply(x_lines, gsub,
                    pattern = "^\\s{1,20}",
                    replacement = "")

  x_page <- lapply(x_lines, stringi::stri_split_regex,
                   pattern = pattern,
                   omit_empty = NA, simplify = TRUE)

  empty_cells <- lapply(seq_along(x_page), function(xx)
    apply(x_page[[xx]], 2, stringi::stri_isempty))
  for(xx in seq_along(empty_cells)) {
    empty_cells[[xx]][is.na(empty_cells[[xx]])] <- TRUE
  }

  sum_columns <- unlist(lapply(seq_along(empty_cells), function(xx)
    apply(apply(empty_cells[[xx]], 2, detect_false), 1, sum)
  )
  )

  most_columns <- table(sum_columns)

  as.numeric(attr(most_columns[order(most_columns, decreasing = TRUE)][1], "names"))

}

detect_false <- function(x) { x == FALSE }


#' Find table locations
#'
#' From input of row numbers of possible table locations, this function detects
#'  subsequent row numbers to identify single tables.
#'
#' @param row_numbers Row numbers of PDF text that are possible table locations.
#'
#' @export
find_table_locations <- function(row_numbers) {
  # find table location takes the parameter(possible table location)

  length_input <- length(row_numbers) - 1
  #Creates indices for subtracting adjacent indices in possible table locations

  diff_adjacent <- unlist(
    lapply(seq_len(length_input), function(xx)
      row_numbers[xx + 1] - row_numbers[xx])
  )
  #diff_adjacent checks the number of lines between possible table location identified above
  #the logic is that, tables will likely have a difference of 1 line between them

  diff_adj_tf <- diff_adjacent < 5
  # selects all lines with less than five lives between between them in possible_table_locations

  rle_df <- data.frame(
    lengths = rle(diff_adj_tf)$lengths,
    values = rle(diff_adj_tf)$values
    #computes the lengths of runs in this case (TRUE/FALSE: from diff_adj_tf )
  )

  nrow_rledf <- nrow(rle_df)
  rle_df$select <- ifelse(rle_df$lengths > 2 & rle_df$values, 1, 0)
  #assign 1 to runs where value is TRUE and 0 to FALSE values

  if(nrow_rledf == 1){
    rle_df$start <- min(c(1, cumsum(rle_df$lengths[1:(nrow(rle_df)-1)]) + 1))
    #reference the beginning of a run in the earlier outcome of possible_table locations
  }else{
    rle_df$start <- c(1, cumsum(rle_df$lengths[1:(nrow(rle_df)-1)]) + 1)
    #reference the beginning of a run in the earlier outcome of possible_table locations
  }
  rle_df$end <- cumsum(rle_df$lengths) + 1
  #reference the end of a run in the earlier outcome of possible_table locations

  rle_df$new_values <- ifelse(rle_df$select, TRUE, FALSE)
  #assign TRUE to runs with select value 1- That is TRUE and have lenght nore than 2

  rle_true <- rle_df[rle_df$new_values == TRUE, ]
  #Filter out data with That is TRUE and have lenght more than 2

  convert_to_true <- lapply(1:nrow(rle_true), function(xx)
    rle_true[xx, 'start']:rle_true[xx, 'end']
  )# create the original indices of the true runs in the possible_table_locations output

  row_numbers_return <- lapply(seq_along(convert_to_true), function(xx)
    row_numbers[convert_to_true[[xx]]]
    ## create the original indices of the true runs in the x_lines output
  )

  row_numbers_return
}

find_table_locations_multicol <- function(possible_table_locations, x_lines) {

  characters_line_split <-unlist(lapply(seq_len(length(possible_table_locations)), function(xx)
    length(strsplit(x_lines[possible_table_locations[[xx]]], "\\s{2,}")[[1]])))


  characters_line_split_Adj <- characters_line_split>2

  #rlee <- rle(characters_line_split_Adj)

  #characters_line_split_Adj <- rlee$lenghts>2

  rle_df_characters <- data.frame(
    lengths = rle(characters_line_split_Adj)$lengths,
    values = rle(characters_line_split_Adj)$values)

  nrow_rledf <- nrow(rle_df_characters)
  rle_df_characters$select <- ifelse(rle_df_characters$lengths > 2 & rle_df_characters$values, 1, 0)

  if(nrow_rledf == 1){
    rle_df_characters$start <- min(c(1, cumsum(rle_df_characters$lengths[1:(nrow(rle_df_characters)-1)]) + 1))
  }else{
    rle_df_characters$start <- c(1, cumsum(rle_df_characters$lengths[1:(nrow(rle_df_characters)-1)]) + 1)
  }

  rle_df_characters$end <- cumsum(rle_df_characters$lengths)
  rle_df_characters$new_values <- ifelse(rle_df_characters$select, TRUE, FALSE)
  rle_df_trues <- rle_df_characters[rle_df_characters$new_values == TRUE, ]

  convert_to_trues <- lapply(1:nrow(rle_df_trues), function(xx)
    rle_df_trues[xx, 'start']:rle_df_trues[xx, 'end']
  )

  row_numbers_returns <- lapply(seq_along(convert_to_trues), function(xx)
    possible_table_locations[convert_to_trues[[xx]]]
    ## create the original indices of the true runs in the x_liness output
  )

  row_numbers_returns

}


add_delimiter <- function(table_lines, delimiter = "\\s{2,}",
                          replacement = "|") {

  gsub(delimiter, replacement, table_lines)

}

#### function to generate sequence
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
