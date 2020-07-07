## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

require(mastercap)
require(tidyverse)
require(magrittr)
data(raw_data, package = "mastercap")

## ----echo = TRUE--------------------------------------------------------------
raw_data %>%
  mastercap::clean_eq_data() %>%
  mastercap::geom_timeline(mindate = "2008-01-01",
                maxdate = "2010-01-01",
                countries = c("China", "Russia", "Japan"))

## ----echo = TRUE--------------------------------------------------------------
raw_data %>%
  mastercap::clean_eq_data() %>%
  mastercap::geom_timeline_label(mindate = "2008-01-01",
                      maxdate = "2010-01-01",
                      countries = c("China", "Russia", "Japan"))

## ----echo = TRUE--------------------------------------------------------------
raw_data %>%
  mastercap::clean_eq_data() %>%
  dplyr::filter(date >= "2008-01-01",
         date <= "2010-01-01",
         country == c("China", "Russia", "Japan")) %>%
  mastercap::eq_map()

