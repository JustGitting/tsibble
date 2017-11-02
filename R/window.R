#' Sliding window calculation
#'
#' `slide()` is an S3 method to carry out rolling window calculation; `slider()`
#' splits the input `x` to a list according to the window size.
#'
#' @param x A vector of numerics, or data frame.
#' @inheritParams purrr::quietly
#' @param ... Additional arguments passed on to `.f`.
#' @param size An integer for window size.
#' @param fill A single value or data frame to replace `NA`.
#'
#' @rdname slide
#' @export
#' @seealso [tile] for tiling window without overlapping observations;
#' [stretch] for expanding more observations
#'
#' @examples
#' x <- 1:10
#' slide(x, mean, size = 3)
#' slide(x, ~ mean(.), size = 3)
#' slide(x, mean, size = 3, fill = 0)
#'
#' # slider ----
#' slider(x, size = 3)
slide <- function(x, .f, ..., size = 1, fill) {
  UseMethod("slide")
}

#' @rdname slide
#' @export
slide.numeric <- function(x, .f, ..., size = 1, fill = NA_real_) {
  lst_x <- slider(x, size = size)
  c(rep_len(fill, size - 1), purrr::map_dbl(lst_x, .f, ...))
}

#' @rdname slide
#' @param deframe TRUE a list is returned. FALSE returns a data frame.
#' @export
slide.data.frame <- function(
  x, .f, ..., size = 1, fill = data.frame(), deframe = TRUE
) {
  lst_x <- slider(x, size = size)
  result <- purrr::map(lst_x, .f, ...)
  output <- c(replicate(n = size - 1, fill, simplify = FALSE), result)
  if (deframe) {
    return(output)
  }
  # currently not support grouped_df/ts
  dplyr::bind_rows(output)
}

#' @rdname slide
#' @export
slider <- function(x, size = 1) {
  bad_window_function(x, size)
  if (is.data.frame(x)) {
    len_x <- nrow(x)
  } else {
    len_x <- length(x)
  }
  lst_idx <- seq_len(len_x - size + 1)
  if (is_atomic(x)) {
    return(purrr::map(lst_idx, ~ x[(.):(. + size - 1)]))
  }
  purrr::map(lst_idx, ~ x[(.):(. + size - 1), , drop = FALSE])
}

#' Tiling window calculation
#'
#' `tile()` is an S3 method to carry out tiling window calculation; `tiler()`
#' splits the input `x` to a list according to the window size.
#'
#' @param x A vector of numerics, or data frame.
#' @inheritParams purrr::quietly
#' @param ... Additional arguments passed on to `.f`.
#' @param size An integer for window size.
#'
#' @rdname tile
#' @export
#' @seealso [slide] for sliding window with overlapping observations;
#' [stretch] for expanding more observations
#'
#' @examples
#' tile(1:10, mean, size = 3)
#' tiler(1:10, size = 3)
tile <- function(x, .f, ..., size = 1) {
  UseMethod("tile")
}

#' @rdname tile
#' @export
tile.numeric <- function(x, .f, ..., size = 1) {
  lst_x <- tiler(x, size = size)
  purrr::map_dbl(lst_x, .f, ...)
}

#' @rdname tile
#' @param deframe TRUE a list is returned. FALSE returns a data frame.
#' @export
tile.data.frame <- function(x, .f, ..., size = 1, deframe = TRUE) {
  lst_x <- tiler(x, size = size)
  if (deframe) {
    return(purrr::map(lst_x, .f, ...))
  }
  purrr::map_df(lst_x, .f, ...)
}

#' @rdname tile
#' @export
tiler <- function(x, size = 1) {
  bad_window_function(x, size)
  if (is.data.frame(x)) {
    seq_x <- nrow(x)
    denom <- seq_x + 1
  } else {
    seq_x <- seq_along(x)
    denom <- length(x) + 1
  }
  frac <- ceiling((seq_x %% denom) / size)
  unname(split(x, frac))
}

#' Stretching window calculation
#'
#' `stretch()` is an S3 method to carry out expanding window calculation; 
#' `stretcher()` splits the input `x` to a list according to the window size.
#'
#' @param x A vector of numerics, or data frame.
#' @inheritParams purrr::quietly
#' @param ... Additional arguments passed on to `.f`.
#' @param size,init An integer for moving and initial window size.
#'
#' @rdname stretch
#' @export
#' @seealso [slide] for sliding window with overlapping observations;
#' [tile] for tiling window without overlapping observations.
#'
#' @examples
#' stretch(1:10, mean, init = 3)
#' stretcher(1:10, init = 3)
stretch <- function(x, .f, ..., size = 1, init = 1) {
  UseMethod("stretch")
}

#' @rdname stretch
#' @export
stretch.numeric <- function(x, .f, ..., size = 1, init = 1) {
  lst_x <- stretcher(x, size = size, init = init)
  purrr::map_dbl(lst_x, .f, ...)
}

#' @rdname stretch
#' @param deframe TRUE a list is returned. FALSE returns a data frame.
#' @export
stretch.data.frame <- function(x, .f, ..., size = 1, init = 1, deframe = TRUE) {
  lst_x <- stretcher(x, size = size, init = init)
  if (deframe) {
    return(purrr::map(lst_x, .f, ...))
  }
  purrr::map_df(lst_x, .f, ...)
}

#' @rdname stretch
#' @export
stretcher <- function(x, size = 1, init = 1) {
  bad_window_function(x, size)
  if (!is_bare_numeric(init, n = 1) || init < 1) {
    abort("The initial window must be a positive integer.")
  }
  incr <- function(init, size) {
    init
    function() {
      init <<- init + size
      init
    }
  }
  counter <- incr(init = init, size = size) 

  ncall <- seq_len(ceiling((length(x) - init) / size) - 1)
  incr_lst <- c(
    list(seq_len(init)), 
    purrr::map(ncall, ~ seq_len(counter())),
    list(seq_along(x))
  )
  purrr::map(incr_lst, function(i) x[i])
}

bad_window_function <- function(x, size) {
  if (is_bare_list(x)) {
    abort("Unsupported input class: list")
  }
  if (!is_bare_numeric(size, n = 1) || size < 1) {
    abort("The window size must be a positive integer.")
  }
}