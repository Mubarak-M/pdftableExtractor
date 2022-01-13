#' Extract tables from pdf documents
#'
#' Using the pdftools package, tables in the loaded pdf document are extracted
#' as a dataframe and returned in a list..
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


extractor_tables <- function(x, path = FALSE,
                           rec = FALSE,
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
  if(all(line_nums== 0)) {
    warning('text not recognized in pdf')

    #Checks if any page has cumulative sum of zero to determine if the text is a pdf file
  } else {
      x_lines <- unlist(stringi::stri_split_lines(x))
      x_lines <- gsub("^\\s+|\\s+$", '', x_lines)#remove all white spaces at the beginning of line or at the end of a line.
      x_lines <- gsub("\002", '-', x_lines)## correctly represent minus sign

    }


    possible_table_locations <- grep(delimiter, x_lines)

    table_locations <- find_table_locations(possible_table_locations)
    #calls find_table_locations function and returns a list of possible number of table and indices of each line in the table in x_lines

    table_locations <- lapply(table_locations, table_location_sequence)
    #full table locations without ommited lines, if any exist previously

    table_text_space <- lapply(seq_along(table_locations), function(xx)
      x_lines[table_locations[[xx]]]) #extract the lines from the original x_lines using the known table locations
    #add delimiter function should be here

    table_text_delim <- lapply(table_text_space, add_delimiter,
                               delimiter = delimiter_table,
                               replacement = replacement)
    #replace white spaces between table text with /

    if(rec){
      tables <- lapply(table_text_delim, rec_table)
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

  if(nrow_rledf==1){
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


