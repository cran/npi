## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(npi)
library(purrr)

## -----------------------------------------------------------------------------
npis <- c(1992708929, 1831192848, 1699778688, 1111111111)  # Last element doesn't exist

out <- npis %>% 
  purrr::map(., ~ npi_search(number = .)) %>% 
  dplyr::bind_rows()

npi_summarize(out)

## -----------------------------------------------------------------------------
codes <- c(90210, 90211, 90212)

zip_3 <- codes %>% 
  purrr::map(., ~ npi_search(postal_code  = .)) %>% 
  dplyr::bind_rows() 

npi_flatten(zip_3)

## -----------------------------------------------------------------------------
npis <- c(1992708929, 1831192848, 1699778688, 1111111111)  # Last element doesn't exist
combined_df  <- data.frame()
for (i in npis) {
  combined_df <- rbind(combined_df, npi_search(number = i))
}

npi_summarize(combined_df)

