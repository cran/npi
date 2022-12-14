## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(npi)

## -----------------------------------------------------------------------------
nyc <- npi_search(city = "New York City")
nyc

## -----------------------------------------------------------------------------
nyc_multi <- npi_search(city = "New York City", state = "NY", enumeration_type = "org")
nyc_multi

## -----------------------------------------------------------------------------
nyc_25 <- npi_search(city = "New York City", limit = 25)
nyc_25

## -----------------------------------------------------------------------------
nyc_300 <- npi_search(city = "New York City", limit = 300)
nyc_300

## -----------------------------------------------------------------------------
npi_summarize(nyc)

## -----------------------------------------------------------------------------
npi_flatten(nyc)

## -----------------------------------------------------------------------------
npi_flatten(nyc, cols = c("basic", "taxonomies"))

