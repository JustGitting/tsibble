#' Return key variables
#'
#' `key()` returns a list of symbols; `key_vars()` gives a character vector.
#'
#' @param x A data frame.
#'
#' @rdname key
#' @examples
#' # A single key for pedestrian data ----
#' key(pedestrian)
#' key_vars(pedestrian)
#'
#' # Nested and crossed keys for tourism data ----
#' key(tourism)
#' key_vars(tourism)
#' @export
key <- function(x) {
  UseMethod("key")
}

#' @export
key.default <- function(x) {
  abort(sprintf("Can't find the `key` in `%s`", class(x)[1]))
}

#' @export
key.tbl_ts <- function(x) {
  attr(x, "key")
}

#' @rdname key
#' @export
key_vars <- function(x) {
  UseMethod("key_vars")
}

#' @export
key_vars.tbl_ts <- function(x) {
  format(key(x))
}

#' @rdname key
#' @export
#' @examples
#' # unkey() only works for a tsibble with 1 key size ----
#' sx <- pedestrian %>% 
#'   filter(Sensor == "Southern Cross Station")
#' unkey(sx)
unkey <- function(x) {
  UseMethod("unkey")
}

#' @export
unkey.tbl_ts <- function(x) {
  nkey <- n_keys(x)
  if (nkey < 2 || nkey == nrow(x)) {
    attr(x, "key") <- structure(id(), class = "key")
    return(x)
  } else {
    abort("`unkey()` must not be applied to a `tbl_ts` of more than 1 key size.")
  }
}

#' Compute sizes of key variables
#'
#' @param x A data frame.
#'
#' @examples
#' key_size(pedestrian)
#' n_keys(pedestrian)
#' key_indices(pedestrian)
#'
#' @rdname key-size
#' @export
key_size <- function(x) {
  UseMethod("key_size")
}

#' @export
key_size.tbl_ts <- function(x) {
  key_indices <- key_indices(x)
  if (is_empty(key_indices)) {
    return(NROW(x))
  }
  vapply(key_indices, length, integer(1))
}

#' @rdname key-size
#' @export
n_keys <- function(x) {
  UseMethod("n_keys")
}

#' @export
n_keys.tbl_ts <- function(x) {
  length(key_size(x))
}

#' @rdname key-size
#' @export
key_indices <- function(x) {
  UseMethod("key_indices")
}

#' @export
key_indices.tbl_ts <- function(x) {
  flat_keys <- key_flatten(key(x))
  grped_key <- grouped_df(x, flat_keys)
  attr(grped_key, "indices")
}

key_distinct <- function(x) { # x = a list of keys (symbols)
  if (is_empty(x)) {
    return(x)
  }
  nest_lgl <- is_nest(x)
  comb_keys <- x[!nest_lgl]
  if (any(nest_lgl)) {
    nest_keys <- purrr::map(x[nest_lgl], ~ .[[1]])
    comb_keys <- c(nest_keys, comb_keys)
  }
  unname(comb_keys)
}

drop_group <- function(x) {
  len <- length(x)
  new_grps <- x[-len] # drop one grouping level
  last_x <- dplyr::last(x)
  if (is_empty(new_grps)) {
    return(id())
  } else if (length(last_x) > 1) {
    return(c(new_grps, list(last_x[-length(last_x)])))
  } else {
    new_grps
  }
}

# this returns a vector of groups/key characters
key_flatten <- function(x) {
  if (is.null(x)) {
    x <- id()
  }
  unname(purrr::map_chr(flatten(x), quo_text2))
}

#' Change/update key variables for a given `tbl_ts`
#'
#' @param .data A `tbl_ts`.
#' @param ... Expressions used to construct the key:
#' * unspecified: drop every single variable from the old key.
#' * `|` and `,` for nesting and crossing factors.
#' @inheritParams as_tsibble
#'
#' @examples
#' # tourism could be identified by Region and Purpose ----
#' tourism %>% 
#'   key_update(Region, Purpose)
#' @export
key_update <- function(.data, ..., validate = TRUE) {
  not_tsibble(.data)
  quos <- enquos(...)
  key <- validate_key(.data, quos)
  build_tsibble(
    .data, key = key, index = !! index(.data), groups = groups(.data),
    regular = is_regular(.data), validate = validate, 
    ordered = is_ordered(.data), interval = interval(.data)
  )
}

# drop some keys
key_reduce <- function(.data, .vars) {
  old_key <- key(.data)
  old_chr <- key_flatten(old_key)
  key_idx <- which(.vars %in% old_chr)
  key_vars <- .vars[key_idx]
  old_lgl <- rep(is_nest(old_key), purrr::map(old_key, length))
  new_lgl <- old_lgl[match(key_vars, old_chr)]

  new_key <- syms(key_vars[!new_lgl])
  if (any(new_lgl)) {
    new_key <- c(list(syms(key_vars[new_lgl])), new_key)
  }
  key_update(.data, !!! new_key)
}

# rename key
key_rename <- function(.data, ...) {
  quos <- enquos(...)
  old_key <- key(.data)
  new_chr <- old_chr <- key_flatten(old_key)
  rhs <- purrr::map_chr(quos, quo_get_expr)
  key_idx <- which(rhs %in% old_chr)
  key_rhs <- rhs[key_idx]
  key_lhs <- names(key_rhs)
  lgl <- FALSE
  if (!is_empty(old_key)) {
    lgl <- rep(is_nest(old_key), purrr::map(old_key, length))
  }
  new_chr[match(key_rhs, old_chr)] <- key_lhs
  new_key <- syms(new_chr[!lgl])
  if (is_empty(new_chr)) {
    new_key <- id()
  } else if (any(lgl)) {
    new_key <- c(list(syms(new_chr[lgl])), new_key)
  }
  dat_key_pos <- match(old_chr, names(.data))
  names(.data)[dat_key_pos] <- new_chr
  build_tsibble(
    .data, key = new_key, index = !! index(.data),
    regular = is_regular(.data), validate = FALSE, 
    ordered = is_ordered(.data), interval = interval(.data)
  )
}

# The function takes a nested key/group str, i.e. `|` sym
# it also handles `-` and `:` and `c`
# return: a list of symbols (if (is_nest) a list of list)
validate_key <- function(data, key) {
  col_names <- colnames(data)
  keys <- parse_key(key)
  if (is_empty(keys)) {
    return(keys)
  }
  nest_lgl <- is_nest(keys)
  valid_keys <- syms(validate_vars(keys[!nest_lgl], col_names))
  if (any(nest_lgl)) {
    nest_keys <- purrr::map(
      keys[nest_lgl],
      ~ syms(validate_vars(flatten(.), col_names))
    )
    valid_keys <- c(nest_keys, valid_keys)
  }
  unname(valid_keys)
}

is_nest <- function(lst_syms) {
  if (is_empty(lst_syms)) {
    return(FALSE)
  }
  unname(purrr::map_lgl(lst_syms, is_list)) # expected to be a list not call
}

parse_key <- function(x) {
  if (is_empty(x)) {
    return(id())
  }
  # purrr::map(x, ~ flatten_nest(.[[-1]]))
  purrr::map(x, flatten_nest)
}

# interpret a nested calls A | B | C
flatten_nest <- function(key) { # call
  if (!is_bare_list(key) && has_length(key, 2) && key[[1]] != sym("-")) {
    return(flatten_nest(key[[2]]))
  }
  if (is_bare_list(key, 2) || length(key) < 3)
    return(key)
  op <- key[[1]]
  x <- key[[2]]
  y <- key[[3]]
  if (op == sym("|")) {
    c(flatten_nest(x), flatten_nest(y))
  } else if (op == sym("-")) {
    c(flatten_nest(x), expr(-flatten_nest(y)))
  } else {
    key
  }
}

