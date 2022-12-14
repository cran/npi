#' @noRd
pluck_vector_from_content <- function(content, col_name) {
  content %>%
    purrr::map(purrr::pluck, col_name) %>%
    unlist(recursive = FALSE)
}



#' @noRd
tidy_results <- function(content) {
  content <- unlist(content, recursive = FALSE)

  tibble::tibble(
    npi = pluck_vector_from_content(content, "number"),
    enumeration_type = pluck_vector_from_content(content, "enumeration_type"),
    basic = list_to_tibble(content, "basic", 1),
    other_names = list_to_tibble(content, "other_names", 2),
    identifiers = list_to_tibble(content, "identifiers", 2),
    taxonomies = list_to_tibble(content, "taxonomies", 2),
    addresses = list_to_tibble(content, "addresses", 2),
    practice_locations = list_to_tibble(content, "practice_locations", 2),
    endpoints = list_to_tibble(content, "endpoints", 2),
    created_date = pluck_vector_from_content(content, "created_epoch"),
    last_updated_date = pluck_vector_from_content(content, "last_updated_epoch")
  )
}



#' @noRd
clean_results <- function(results) {
  convert_epoch_to_date <- function(col) {
    ifelse(
      nchar(as.character(col)) == 13,
      as.numeric(col) / 1000,
      as.numeric(col)
    )
  }

  epoch_to_date <- purrr::as_mapper(
    ~ as.POSIXct(convert_epoch_to_date(.x), origin = "1970-01-01", tz = "UTC")
  )

  results %>%
    dplyr::mutate(
      enumeration_type = dplyr::case_when(
        enumeration_type == "NPI-1" ~ "Individual",
        enumeration_type == "NPI-2" ~ "Organization",
        TRUE ~ NA_character_
      )
    ) %>%
    dplyr::mutate_at(dplyr::vars(dplyr::ends_with("_date")), epoch_to_date)
}



#' @noRd
list_to_tibble <- function(content, col_name, depth = 1L) {
  checkmate::assert_choice(depth, choices = c(1L, 2L))

  level_one <- purrr::map(content, col_name)

  if (depth == 1L) {
    out <- purrr::map(level_one, tibble::as_tibble)
    return(out)
  }

  purrr::map(level_one, purrr::map_df, dplyr::bind_rows)
}



#' Extract list column by key
#'
#' @param df A data frame
#' @param list_col The quoted name of a list column in \code{df}
#' @param key One or more quoted names of columns in \code{df} to keep alongside
#'   the unnested columns of \code{list_col} in the result. If the value is
#'   \code{NULL}, the result will just unnest \code{list_col}.
#' @return A data frame with the column(s) specified in \code{key} followed by
#'   the columns unnested from \code{list_col}
#' @examples
#' # Load sample data
#' data("npis")
#'
#' # Get basic list column by NPI
#' get_list_col(npis, "basic")
#' get_list_col(npis, "taxonomies")
#' @noRd
get_list_col <- function(df, list_col = NULL, key = "npi") {
  if (!is.data.frame(df)) {
    abort_bad_argument(arg = "df", must = "be data frame", not = df)
  }

  df <- df[, c(key, list_col)]

  if (nrow(tidyr::unnest(df, !!rlang::sym(list_col))) > 0L) {
    sep_val <- "_"
  } else {
    sep_val <- NULL
  }

  # Make unnest work with older and newer versions of tidyr
  if (tidyr_new_interface()) {
    # Old interface
    tidyr::unnest(df, !!rlang::sym(list_col), .sep = sep_val)
  } else {
    # New interface
    tidyr::unnest(df, !!rlang::sym(list_col), names_sep = sep_val)
  }
}
