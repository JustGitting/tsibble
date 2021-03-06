# Unlike zoo::yearmon and zoo::yearqtr based on numerics,
# tsibble::yearmth and tsibble::yearqtr are based on the "Date" class.

#' Represent year-month or year-quarter objects
#'
#' Create or coerce using `yearmonth()`, or `yearquarter()`
#'
#' @param x Other object.
#'
#' @return Year-month (`yearmonth`) or year-quarter (`yearquarter`)
#' objects.
#' @details It's a known issue that these attributes will be dropped when using
#' [group_by] and [mutate] together. It is recommended to [ungroup] first, and
#' then use [mutate].
#'
#' @section Index functions:
#' The tsibble `yearmonth()` and `yearquarter()` function preserve the time zone of 
#' the input `x`, contrasting to their zoo counterparts.
#'
#' @export
#' @rdname period
#' @seealso [pull_interval]
#'
#' @examples
#' # coerce dates to yearmonth, yearquarter ----
#' x <- seq(as.Date("2016-01-01"), as.Date("2016-12-31"), by = "1 month")
#' yearmonth(x)
#' yearquarter(x)
#'
#' # coerce numerics to yearmonth, yearquarter ----
#' yearmonth(seq(2010, 2017, by = 1 / 12))
#' yearquarter(seq(2010, 2017, by = 1 / 4))
#'
#' # coerce yearmonths to yearquarter ----
#' y <- yearmonth(x)
#' yearquarter(y)
yearmonth <- function(x) {
  UseMethod("yearmonth")
}

as_yearmonth <- function(x) {
  structure(x, class = c("yearmonth", "Date"))
}

#' @export
c.yearmonth <- function(..., recursive = FALSE) {
  as_yearmonth(NextMethod())
}

#' @export
rep.yearmonth <- function(x, ...) {
  as_yearmonth(NextMethod())
}

#' @export
unique.yearmonth <- function(x, incomparables = FALSE, ...) {
  as_yearmonth(NextMethod())
}

#' @export
yearmonth.POSIXt <- function(x) {
  posix <- split_POSIXt(x)
  month <- formatC(posix$mon, flag = 0, width = 2)
  result <- as.Date(paste(posix$year, month, "01", sep = "-"))
  as_yearmonth(result)
}

#' @export
yearmonth.Date <- yearmonth.POSIXt

#' @export
yearmonth.yearmonth <- function(x) {
  as_yearmonth(x)
}

#' @export
yearmonth.numeric <- function(x) {
  year <- trunc(x)
  month <- formatC((x %% 1) * 12 + 1, flag = 0, width = 2)
  result <- as.Date(paste(year, month, "01", sep = "-"))
  as_yearmonth(result)
}

#' @export
yearmonth.yearmth <- yearmonth.numeric

#' @export
format.yearmonth <- function(x, format = "%Y %b", ...) {
  format.Date(x, format = format, ...)
}

#' @export
print.yearmonth <- function(x, format = "%Y %b", ...) {
  print(format(x, format = format, ...))
  invisible(x)
}

#' @export
obj_sum.yearmonth <- function(x) {
  rep("mth", length(x))
}

#' @export
is_vector_s3.yearmonth <- function(x) {
  TRUE
}

#' @export
pillar_shaft.yearmonth <- function(x, ...) {
  out <- format(x)
  pillar::new_pillar_shaft_simple(out, align = "right", min_width = 10)
}

#' @rdname period
#' @export
yearquarter <- function(x) {
  UseMethod("yearquarter")
}

as_yearquarter <- function(x) {
  structure(x, class = c("yearquarter", "Date"))
}

#' @export
c.yearquarter <- function(..., recursive = FALSE) {
  as_yearquarter(NextMethod())
}

#' @export
rep.yearquarter <- function(x, ...) {
  as_yearquarter(NextMethod())
}

#' @export
unique.yearquarter <- function(x, incomparables = FALSE, ...) {
  as_yearquarter(NextMethod())
}

#' @export
yearquarter.POSIXt <- function(x) {
  posix <- split_POSIXt(x)
  qtrs <- formatC(posix$mon - (posix$mon - 1) %% 3, flag = 0, width = 2)
  result <- as.Date(paste(posix$year, qtrs, "01", sep = "-"))
  as_yearquarter(result)
}

#' @export
yearquarter.Date <- yearquarter.POSIXt

#' @export
yearquarter.yearmonth <- yearquarter.POSIXt

#' @export
yearquarter.yearquarter <- function(x) {
  as_yearquarter(x)
}

#' @export
yearquarter.numeric <- function(x) {
  year <- trunc(x)
  last_month <- trunc((x %% 1) * 4 + 1) * 3
  first_month <- formatC(last_month - 2, flag = 0, width = 2)
  result <- as.Date(paste(year, first_month, "01", sep = "-"))
  as_yearquarter(result)
}

#' @export
yearquarter.yearqtr <- yearquarter.numeric

#' @importFrom lubridate as_date
#' @importFrom lubridate tz
#' @importFrom lubridate tz<-
as_date.yearquarter <- function(x, ...) {
  tz_x <- tz(x)
  class(x) <- "Date"
  tz(x) <- tz_x
  x
}

as_date.yearmonth <- function(x, ...) {
  tz_x <- tz(x)
  class(x) <- "Date"
  tz(x) <- tz_x
  x
}

#' @export
as.Date.yearquarter <- as_date.yearquarter

#' @export
as.Date.yearmonth <- as_date.yearmonth

#' @export
format.yearquarter <- function(x, format = "%Y Q%q", ...) {
  x <- as_date(x)
  year <- lubridate::year(x)
  year_sym <- "%Y"
  if (grepl("%y", format)) {
    year <- sprintf("%02d", year %% 100)
    year_sym <- "%y"
  } else if (grepl("%C", format)) {
    year <- year %/% 100
    year_sym <- "%C"
  }
  qtr <- lubridate::quarter(x)
  qtr_sub <- purrr::map_chr(qtr, ~ gsub("%q", ., x = format))
  year_sub <- purrr::map2_chr(year, qtr_sub, ~ gsub(year_sym, .x, x = .y))
  year_sub
}

#' @export
print.yearquarter <- function(x, format = "%Y Q%q", ...) {
  print(format(x, format = format))
  invisible(x)
}

#' @export
obj_sum.yearquarter <- function(x) {
  rep("qtr", length(x))
}

#' @export
is_vector_s3.yearquarter <- is_vector_s3.yearmonth

#' @export
pillar_shaft.yearquarter <- pillar_shaft.yearmonth

split_POSIXt <- function(x) {
  posix <- as.POSIXlt(x, tz = lubridate::tz(x))
  posix$mon <- posix$mon + 1
  posix$year <- posix$year + 1900
  posix
}

#' @export
seq.yearmonth <- function(
  from, to, by, length.out = NULL, along.with = NULL,
  ...) {
  if (!is_bare_numeric(by, n = 1)) {
    abort("`by` only takes a numeric.")
  }
  by_mth <- paste(by, "month")
  yearmonth(seq_date(
    from = from, to = to, by = by_mth, length.out = length.out,
    along.with = along.with, ...
  ))
}

#' @export
seq.yearquarter <- function(
  from, to, by, length.out = NULL, along.with = NULL,
  ...) {
  if (!is.numeric(by)) {
    abort("`by` only takes a numeric.")
  }
  by_qtr <- paste(by, "quarter")
  yearquarter(seq_date(
    from = from, to = to, by = by_qtr, length.out = length.out,
    along.with = along.with, ...
  ))
}

#' @export
`[.yearmonth` <- function(x, i) {
  yearmonth(as_date(x)[i])
}

#' @export
`[.yearquarter` <- function(x, i) {
  yearquarter(as_date(x)[i])
}

#' @export
as.POSIXlt.yearquarter <- function(x, tz = "", ...) {
  as.POSIXlt(as_date(x), tz = tz, ...)
}

seq_date <- function(
  from, to, by, length.out = NULL, along.with = NULL,
  ...) {
  if (missing(from))
    stop("'from' must be specified")
  if (!inherits(from, "Date"))
    stop("'from' must be a \"Date\" object")
  if (length(as.Date(from)) != 1L)
    stop("'from' must be of length 1")
  if (!missing(to)) {
    if (!inherits(to, "Date"))
      stop("'to' must be a \"Date\" object")
    if (length(as.Date(to)) != 1L)
      stop("'to' must be of length 1")
  }
  if (!is.null(along.with)) { # !missing(along.with) in seq.Date
    length.out <- length(along.with)
  } else if (!is.null(length.out)) {
    if (length(length.out) != 1L)
      stop("'length.out' must be of length 1")
    length.out <- ceiling(length.out)
  }
  status <- c(!missing(to), !missing(by), !is.null(length.out))
  if (sum(status) != 2L)
    stop("exactly two of 'to', 'by' and 'length.out' / 'along.with' must be specified")
  if (missing(by)) {
    from <- unclass(as.Date(from))
    to <- unclass(as.Date(to))
    res <- seq.int(from, to, length.out = length.out)
    return(structure(res, class = "Date"))
  }
  if (length(by) != 1L)
    stop("'by' must be of length 1")
  valid <- 0L
  if (inherits(by, "difftime")) {
    by <- switch(attr(by, "units"), secs = 1/86400, mins = 1/1440,
        hours = 1/24, days = 1, weeks = 7) * unclass(by)
  } else if (is.character(by)) {
    by2 <- strsplit(by, " ", fixed = TRUE)[[1L]]
    if (length(by2) > 2L || length(by2) < 1L)
      stop("invalid 'by' string")
    valid <- pmatch(by2[length(by2)], c("days", "weeks",
      "months", "quarters", "years"))
    if (is.na(valid))
      stop("invalid string for 'by'")
    if (valid <= 2L) {
      by <- c(1, 7)[valid]
      if (length(by2) == 2L)
        by <- by * as.integer(by2[1L])
    } else by <- if (length(by2) == 2L)
      as.integer(by2[1L])
    else 1
  } else if (!is.numeric(by))
    stop("invalid mode for 'by'")
  if (is.na(by))
    stop("'by' is NA")
  if (valid <= 2L) {
    from <- unclass(as.Date(from))
    if (!is.null(length.out))
      res <- seq.int(from, by = by, length.out = length.out)
    else {
      to0 <- unclass(as.Date(to))
      res <- seq.int(0, to0 - from, by) + from
    }
    res <- structure(res, class = "Date")
  } else {
    r1 <- as.POSIXlt(from)
    if (valid == 5L) {
      if (missing(to)) {
        yr <- seq.int(r1$year, by = by, length.out = length.out)
      } else {
        to0 <- as.POSIXlt(to)
        yr <- seq.int(r1$year, to0$year, by)
      }
      r1$year <- yr
      res <- as.Date(r1)
    } else {
      if (valid == 4L)
        by <- by * 3
      if (missing(to)) {
        mon <- seq.int(r1$mon, by = by, length.out = length.out)
      }
      else {
        to0 <- as.POSIXlt(to)
        mon <- seq.int(r1$mon, 12 * (to0$year - r1$year) +
          to0$mon, by)
      }
      r1$mon <- mon
      res <- as.Date(r1)
    }
  }
  if (!missing(to)) {
    to <- as.Date(to)
    res <- if (by > 0)
      res[res <= to]
    else res[res >= to]
  }
  res
}
