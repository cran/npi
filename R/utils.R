# Global variables for GET request
API_VERSION <- "2.1" # Referenced in `npi_search()`
BASE_URL <- "https://npiregistry.cms.hhs.gov/api/"
USER_AGENT <- paste(
  paste0("npi/", utils::packageVersion("npi")),
  "(http://github.com/ropensci/npi)"
)
MAX_N_PER_REQUEST <- 200L

#' Handle bad function arguments
#'
#' Error handler to abort a bad argument, `arg`, based on its actual vs.
#' expected type or class, and display a templated error message.
#'
#' @param arg Function argument name as character vector
#' @param must Text to relate argument's name to its expected type
#' @param not Function argument (optional)
#' @param method Either "typeof" (default) or "class"
#' @return Error handler of class `error_bad_argument` with templated message
#' and metadata
#' @examples
#' a <- "foo"
#' b <- 1L
#'
#' # Check argument type
#' abort_bad_argument("a", must = "be integer", not = a) # Error
#' abort_bad_argument("b", must = "be integer", not = b) # No error
#'
#' # Check argument class
#' c <- factor(a)
#' abort_bad_argument("a", must = "be factor", not = a, method = "class")
#' @noRd
abort_bad_argument <- function(arg, must, not = NULL,
                               method = c("typeof", "class")) {
  method <- match.arg(method)
  msg <- paste0("`", arg, "`", " must ", must)
  if (!is.null(not)) {
    not <- ifelse(method == "typeof", typeof(not), class(not))
    msg <- paste0(msg, ", not ", not, ".")
  }

  rlang::abort("error_bad_argument",
    message = msg,
    arg = arg,
    must = must,
    not = not
  )
}


#' Check if candidate NPI number is valid
#'
#' Check whether a number is a valid NPI number per the specifications detailed
#' in the Final Rule for the Standard Unique Health Identifier for Health Care
#' Providers (69 FR 3434).
#'
#' @param x 10-digit candidate NPI number
#' @return Boolean indicating whether \code{npi} is valid
#' @family utility functions
#' @examples
#' npi_is_valid(1234567893) # TRUE
#' npi_is_valid(1234567898) # FALSE
#' @export
npi_is_valid <- function(x) {
  if (stringr::str_length(x) != 10 ||
    stringr::str_detect(x, "\\d{10}",
      negate = TRUE
    )) {
    rlang::abort("`x` must be a 10-digit number.")
  }

  x <- as.character(x)

  # Prefix the NPI with code for US health applications per US governement
  # requirements
  x <- paste0("80840", x)

  # Validate number using the Luhn algorithm
  checkLuhn::checkLuhn(x)
}



#' Clean up credentials
#'
#' @param x Character vector of credentials
#' @return List of cleaned character vectors, with one list element per element
#'   of \code{x}
#' @noRd
clean_credentials <- function(x) {
  if (!is.character(x)) {
    stop("x must be a character vector")
  }

  out <- gsub("\\.", "", x)
  out <- stringr::str_split(out, "[,\\s;]+", simplify = FALSE)
  out
}


#' Format United States (US) ZIP codes
#'
#' @param x Character vector
#'
#' @return Length \code{x} character vector hyphenated for ZIP+4 or 5-digit ZIP.
#'   Invalid elements of \code{x} are not formatted.
#' @noRd
hyphenate_full_zip <- function(x) {
  checkmate::assert(
    checkmate::check_character(x),
    checkmate::check_integerish(x),
    combine = "or"
  )

  x <- as.character(x)

  # Add a hyphen in the right place iff the element has exactly 9 digits;
  # otherwise, leave the (possibly) invalid ZIP alone
  zip_regex <- "^[[:digit:]]{9}$"
  ifelse(
    stringr::str_detect(x, zip_regex),
    paste0(stringr::str_sub(x, 1, 5), "-", stringr::str_sub(x, 6, 9)),
    x
  )
}


#' Create full address from elements
#'
#' @param df Data frame
#' @param address_1 Quoted column name in \code{df} containing a character
#'   vector of first-street-line addresses
#' @param address_2 Quoted column name in \code{df} containing a character
#'   vector of second-street-line addresses
#' @param city Quoted column name in \code{df} containing a character vector of
#'   cities
#' @param state Quoted column name in \code{df} containing a character vector of
#'   two-letter state abbreviations
#' @param postal_code Quoted column name in \code{df} containing a character or
#'   numeric vector of postal codes
#'
#' @return Character vector containing full one-line addresses
#' @noRd
make_full_address <-
  function(df,
           address_1,
           address_2,
           city,
           state,
           postal_code) {
    stopifnot(
      is.data.frame(df),
      all(c(
        address_1, address_2, city, state, postal_code
      ) %in% names(df))
    )

    stringr::str_c(
      stringr::str_trim(df[[address_1]], "both"),
      ifelse(df[[address_2]] == "", "", " "),
      stringr::str_trim(df[[address_2]], "both"),
      ", ",
      stringr::str_trim(df[[city]], "both"),
      ", ",
      stringr::str_trim(df[[state]], "both"),
      " ",
      stringr::str_trim(df[[postal_code]], "both")
    )
  }

#' Check for new tidyr interface
#'
#' @return Boolean indicating whether a newer version of tidyr is installed
#' @noRd
tidyr_new_interface <- function() {
  utils::packageVersion("tidyr") <= "0.8.99"
}


#' Validate wildcard rules
#' @param x Length 1 character vector
#' @return Boolean indicated whether the rules pass (TRUE) or fail (FALSE)
#' @noRd
validate_wildcard_rules <- function(x) {
  if ((!is.character(x) && !is.numeric(x)) || length(x) > 1) {
    rlang::abort(
      "x must be a character vector with length 1",
      "bad_wildcard_error"
    )
  }

  wildcard_pattern <- "\\*"

  # Atomic test functions
  n_wildcards <- function(x) {
    stringr::str_count(x, wildcard_pattern)
  }
  ends_in_wildcard <-
    function(x) {
      stringr::str_ends(x, wildcard_pattern)
    }
  enough_chars <- function(x) {
    (nchar(x) - n_wildcards(x)) >= 2
  }

  # 2 or more wildcards present --> FAIL
  if (n_wildcards(x) > 1) {
    rlang::abort(
      paste0(
        n_wildcards(x),
        " wildcard characters (*) detected.\nA maximum of one wildcard \
        character is allowed per argument."
      ),
      "bad_wildcard_error"
    )
  }

  # 1 wildcard present
  if (n_wildcards(x) == 1) {
    # non-trailing wildcard
    if (isFALSE(ends_in_wildcard(x))) {
      rlang::abort(
        "Argument ending in a non-trailing wildcard character (*) detected.\n \
        When present, the wildcard character must appear at the end of the \
        character string.",
        "bad_wildcard_error"
      )
    }

    # 1 trailing wildcard and less than 2 non-wildcard characters precede it
    if (isFALSE(enough_chars(x))) {
      rlang::abort(
        "Arguments ending in a wildcard character (*) must be preceded by two \
        or more non-wildcard characters.",
        "bad_wildcard_error"
      )
    }
  }

  TRUE
}
