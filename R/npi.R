#' @details \pkg{npi} makes it easy to search and work with data from the U.S.
#' National Provider Identifier (NPI) Registry API (v2.1) directly from R.
#' Obtain rich administrative data linked to a specific individual or
#' organizational healthcare provider, or perform advanced searches based on
#' provider name, location, type of service, credentials, and many other
#' attributes. npi provides convenience functions for data extraction so you can
#' spend less time wrangling data and more time putting data to work.
#'
#' There are three functions you're likely to need from this package. The first
#' is \code{\link{npi_search}}, which allows you to query the NPI Registry and
#' returns up to 1,200 full NPI records as a data frame (tibble). Next, you can
#' use \code{\link{npi_summarize}} on these results to obtain a human-readable
#' summary of each record. Finally, \code{\link{npi_flatten}} extracts and
#' flattens conceptually-related subsets of data into a tibble that are joined
#' by the `npi` column into an analysis-ready object.
#'
#' @section Package options:
#'
#'   \pkg{npi}'s default user agent is the URL of the package's GitHub
#'   repository, \url{https://github.com/ropensci/npi}. You can customize
#'   it by setting the \code{npi_user_agent} option:
#'
#'   \code{options(npi_user_agent = "your_user_agent_here")}
#' @keywords internal
"_PACKAGE"
