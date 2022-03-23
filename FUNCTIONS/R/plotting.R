
#' Create colors for a continuous variable and the legend.
#'
#' @param data    Numerical data to be colorized
#' @param colors  A vector o colors to be used
#' @param breaks  How many discrete colors to use
#' @param NA_col  Color to use when NA or Inf
#' @param Increas Increasing or decreasing colors
#'
#' @return        A list with 3 vectors.
#'               `cols`    The actual color of the data
#'               `rang`    The range of values corresponding to `rangcol`
#'               `rangcol` The color of the corresponding range
#' @export
clr_smth <- function( data,
                      colors  = c('blue','red'),
                      breaks  = 20,
                      NA_col  = "black",
                      Increas = TRUE) {

  if (Increas==FALSE) { colors <- rev(colors) }

  ## create color pallete
  rbPal <- colorRampPalette(colors)(breaks)
  ## colorize data
  cols <- rbPal[cut(data, breaks = breaks)]
  ## levels of ranges for legend
  rang <- sort(unique(cut(data, breaks = breaks)))
  ## provide a color for unplotable data
  cols[is.na(data)      ] <- NA_col
  cols[is.infinite(data)] <- NA_col
  ## return output
  list(
    cols    = cols,
    rang    = rang,
    rangcol = rbPal[rang]
  )
}




