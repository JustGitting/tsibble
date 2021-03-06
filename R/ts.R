#' Coerce a tsibble to a time series
#'
#' @param x A `tbl_ts` object.
#' @param value A measured variable of interest to be spread over columns, if
#' multiple measures.
#' @param frequency A smart frequency with the default `NULL`. If set, the 
#' preferred frequency is passed to `ts()`.
#' @param fill A value replaces missing values.
#' @param ... Ignored for the function.
#'
#' @return A `ts` object.
#' @export
#'
#' @examples
#' # a monthly series ----
#' x1 <- as_tsibble(AirPassengers)
#' as.ts(x1)
#' 
#' # equally spaced over trading days, not smart enough to guess frequency ----
#' x2 <- as_tsibble(EuStockMarkets)
#' head(as.ts(x2, frequency = 260))
as.ts.tbl_ts <- function(x, value, frequency = NULL, fill = NA, ...) {
  value <- enquo(value)
  key_vars <- key(x)
  if (any(is_nest(key_vars)) || length(key_vars) > 1) {
    abort("`as.ts()` can't deal with nested or crossed keys.")
  }
  mat_ts <- spread_tsbl(x, value = value, fill = fill)
  finalise_ts(mat_ts, index = index(x), frequency = frequency)
}

finalise_ts <- function(data, index, frequency = NULL) {
  idx_time <- time(dplyr::pull(data, !! index))
  out <- data %>%
    select(- !! index)
  if (NCOL(out) == 1) {
    out <- out[[1]]
  }
  if (is.null(frequency)) {
    frequency <- stats::frequency(idx_time)
  }
  stats::ts(out, stats::start(idx_time), frequency = frequency)
}

#' @importFrom stats as.ts tsp<- time
#' @export
time.yearmonth <- function(x, ...) {
  freq <- guess_frequency(x)
  y <- lubridate::year(x) + (lubridate::month(x) - 1) / freq
  stats::ts(y, start = min0(y), frequency = freq)
}

#' @export
time.yearquarter <- function(x, ...) {
  freq <- guess_frequency(x)
  y <- lubridate::year(x) + (lubridate::quarter(x) - 1) / freq
  stats::ts(y, start = min0(y), frequency = freq)
}

#' @export
time.numeric <- function(x, ...) {
  stats::ts(x, start = min0(x), frequency = 1)
}

#' @export
time.Date <- function(x, frequency = NULL, ...) {
  if (is.null(frequency)) {
    frequency <- guess_frequency(x)
  }
  y <- lubridate::decimal_date(x)
  stats::ts(x, start = min0(y), frequency = frequency)
}

#' @export
time.POSIXt <- function(x, frequency = NULL, ...) {
  if (is.null(frequency)) {
    frequency <- guess_frequency(x)
  }
  y <- lubridate::decimal_date(x)
  stats::ts(x, start = min0(y), frequency = frequency)
}

#' Guess a time frequency from other index objects
#'
#' A possible frequency passed to the `ts()` function
#'
#' @param x An index object including "yearmonth", "yearquarter", "Date" and others.
#'
#' @details If a series of observations are collected more frequently than 
#' weekly, it is more likely to have multiple seasonalities. This function
#' returns a frequency value at its nearest ceiling time resolution. For example, 
#' hourly data would have daily, weekly and annual frequencies of 24, 168 and 8766
#' respectively, and hence it gives 24.
#'
#' @references <https://robjhyndman.com/hyndsight/seasonal-periods/>
#'
#' @export
#'
#' @examples
#' guess_frequency(yearquarter(seq(2016, 2018, by = 1 / 4)))
#' guess_frequency(yearmonth(seq(2016, 2018, by = 1 / 12)))
#' guess_frequency(seq(as.Date("2017-01-01"), as.Date("2017-01-31"), by = 1))
#' guess_frequency(seq(
#'   as.POSIXct("2017-01-01 00:00"), as.POSIXct("2017-01-10 23:00"), 
#'   by = "1 hour"
#' ))
guess_frequency <- function(x) {
  UseMethod("guess_frequency")
}

#' @export
guess_frequency.yearmonth <- function(x) {
  12 / pull_interval(x)$month
}

#' @export
guess_frequency.yearquarter <- function(x) {
  4 / pull_interval(x)$quarter
}

#' @export
guess_frequency.Date <- function(x) {
  7 / pull_interval(x)$day
}

#' @export
guess_frequency.POSIXt <- function(x) {
  int <- pull_interval(x)
  number <- int$hour + int$minute / 60 + int$second / 3600
  if (number > 1 / 60) {
    return(24 / number)
  } else if (number > 1 / 3600 && number <= 1 / 60) {
    return(3600 * number)
  } else {
    3600 * 60 * number
  }
}
