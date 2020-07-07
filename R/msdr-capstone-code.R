require(tidyverse)
require(lubridate)
require(ggplot2)
require(leaflet)
require(readr)
require(stringr)
require(magrittr)
require(dplyr)


#######################################
# Module 1: Obtain and clean the data #
#######################################

# Read in data
# raw_data <- readr::read_tsv("signif.txt")

#' Consolidate the date column
#'
#' This function takes the multiple date columns (day, year month, etc.) of the raw data
#' and converts it into a single clean lubridate::ymd() format. It fills in dates for earthquakes
#' that do not have precise dates available. It also readjusts BCE dates to work with Lubridate.
#'
#' Errors are likely caused by inputting data that is not valid earthquake data in Tibble form.
#'
#' @param x must be a valid earthquake dataset read in in the Tibble format
#'
#' @return The function returns a tibble with a new "date" column
#'
#' @importFrom dplyr mutate
#' @importFrom lubridate ymd

consolidate_date_column <- function (x) {
  x %>% dplyr::mutate(month = ifelse(is.na(month), 1, month),
               day = ifelse(is.na(day), 1, day)) %>% # Create placeholder date for NAs
    dplyr::mutate(adj_year = year + -min(year) + 1000) %>% # Used to handle dates < 1000CE in lubridate
    dplyr::mutate(date = lubridate::ymd(paste(adj_year, month, day, sep="-"))) %>% # Create date column
    dplyr::mutate(date = date - lubridate::years(-min(year) + 1000)) # Readjust dates
}

#' Function to ensure latitude and longitude are numeric class
#'
#' Internal function that just ensures lon and lat are numeric.
#'
#' @param x must be a valid earthquake data tibble
#'
#' @return Same tibble with lon and lat in numeric format
#'
#' @importFrom dplyr mutate

numeric_lonlat <- function(x) {
  x %>% dplyr::mutate(longitude = as.numeric(longitude), latitude = as.numeric(latitude))
}

#' Clean up earthquake location column
#'
#' Applies several string manipulation functions to clean up the location_name column.
#' It first removes the country name from the beginning of the string. Then it converts to
#' title case. Then it removes white space.
#'
#' @param x must be a valid earthquake dataset read in in the Tibble format
#'
#' @return Returns a tibble with new country and location_name columns
#'
#' @importFrom dplyr mutate
#' @importFrom stringr str_remove_all str_to_title str_squish

eq_location_clean <- function(x) { # Special function as requested by assignment
  x %>%
    dplyr::mutate(location_name = stringr::str_remove_all(location_name, pattern = paste0(country,"\\:"))) %>% # Remove country name and colon
    dplyr::mutate(location_name = stringr::str_to_title(location_name)) %>% # Convert to title case
    dplyr::mutate(location_name = stringr::str_squish(location_name)) %>% # Remove white space
    dplyr::mutate(country = stringr::str_to_title(country))
}

#' Function to take out unnecessary columns -- many are redundant or riddles with NAs
#'
#' Internal function to minimize number of columns in the earthquake tibble
#'
#' @param x must be a valid earthquake dataset read in in the Tibble format
#'
#' @return A tibble with a few select columns
#'
#' @importFrom dplyr select

reduce_columns <- function(x) {
  x %>% dplyr::select(i_d, date, longitude, latitude, country, location_name, focal_depth,
               magnitude = eq_primary, intensity, deaths, injuries, houses_destroyed,
               houses_damaged)
}

#' Convert earthquake data from raw to tidy
#'
#' This function applies all the earthquake data cleaning operations at once. It consolidates
#' dates, numericizes longitude and latitude, cleans the location names, and reduces the number
#' of columns.
#'
#' @param x is a valid earthquake dataset imported using read_tsv()
#'
#' @return Returns a fully tidied Tibble
#'
#' @importFrom dplyr tbl_df

clean_eq_data <- function (x) {
  x <- dplyr::tbl_df(x)
  names(x) <- stringr::str_to_lower(names(x))
  x %>% consolidate_date_column() %>% numeric_lonlat() %>% eq_location_clean() %>% reduce_columns
}

# Clean and tidy the raw data
# df <- clean_eq_data(raw_data)

#################################
# Module 2: Visualization tools #
#################################

#' Plots a timeline of earthquakes
#'
#' This function creates a plot of earthquakes by date. The user can specify a minimum
#' and maximum date and select the countries by which to filter.
#'
#' Errors are likely due to an invalid tibble or incorrectly formatted inputs for the
#' other paremeters. Countries parameter only filters for countries matched in the tibble.
#'
#' @param df is a valid tidy earthquake tibble
#' @param mindate is the minimum date in "YYYY-MM-DD" format
#' @param maxdate is the maximum date in "YYYY-MM-DD" format
#' @param countries is a vector list of countries
#'
#' @return A timeilne plot of earthquakes
#'
#' @importFrom dplyr filter mutate
#' @importFrom ggplot2 ggplot geom_point aes theme labs guides

geom_timeline <- function(df, mindate, maxdate, countries) {
    df %>% dplyr::filter(date >= mindate,
                  date <= maxdate,
                  country %in% countries) %>%
    dplyr::mutate(vert = as.integer(factor(country))) -> df_filtered
    df_filtered %>%
      ggplot2::ggplot() +
      ggplot2::geom_point(ggplot2::aes(x = date,
                     y = factor(country, ordered = TRUE),
                     size = magnitude,
                     color = deaths,
                     alpha = 0.5)) +
      ggplot2::theme(legend.position="bottom",
            panel.background = element_rect(fill = 'white'),
            panel.grid.major.y = element_line(color = 'grey', size = 0.25),
            panel.grid.major.x = element_line(color = NA, size = 0.25),
            axis.line.x = element_line(color = "black", size = .25),
            axis.ticks.y = element_line(color = NA)) +
      ggplot2::labs(x = "DATE",
           y = "",
           size = "Richter scale value",
           color = "Deaths",
           alpha = "") +
      ggplot2::guides(alpha = FALSE)
}

#' Plots a labeled timeline of earthquakes
#'
#' This function is similar to geom_timeline but also adds labels to the timeline.
#' The user can specify a minimum and maximum date and select the countries by which to filter.
#'
#' Errors are likely due to an invalid tibble or incorrectly formatted inputs for the
#' other paremeters. Countries parameter only filters for countries matched in the tibble.
#'
#' @param df is a valid tidy earthquake tibble
#' @param mindate is the minimum date in "YYYY-MM-DD" format
#' @param maxdate is the maximum date in "YYYY-MM-DD" format
#' @param countries is a vector list of countries
#'
#' @return A timeilne plot of earthquakes
#'
#' @importFrom dplyr filter mutate top_n
#' @importFrom ggplot2 ggplot geom_point aes theme labs guides

geom_timeline_label <- function(df, mindate, maxdate, countries) {
  df %>% dplyr::filter(date >= mindate,
                       date <= maxdate,
                       country %in% countries) %>%
    dplyr::mutate(vert = as.integer(factor(country))) -> df_filtered
  df_filtered %>%
    ggplot2::ggplot() +
    ggplot2::geom_point(ggplot2::aes(x = date,
                                     y = factor(country, ordered = TRUE),
                                     size = magnitude,
                                     color = deaths,
                                     alpha = 0.5)) +
    ggplot2::theme(legend.position="bottom",
                   panel.background = element_rect(fill = 'white'),
                   panel.grid.major.y = element_line(color = 'grey', size = 0.25),
                   panel.grid.major.x = element_line(color = NA, size = 0.25),
                   axis.line.x = element_line(color = "black", size = .25),
                   axis.ticks.y = element_line(color = NA)) +
    ggplot2::labs(x = "DATE",
                  y = "",
                  size = "Richter scale value",
                  color = "Deaths",
                  alpha = "") +
    ggplot2::guides(alpha = FALSE) +
    ggplot2::geom_linerange(data = dplyr::top_n(df_filtered, 5, df_filtered$magnitude),
                            ggplot2::aes(x = date,
                                         ymin = vert,
                                         ymax = vert + 0.2),
                            alpha=0.2,
                            inherit.aes=FALSE) +
    ggplot2::geom_text(data = dplyr::top_n(df_filtered, 5, df_filtered$magnitude),
                       ggplot2::aes(label = location_name, x = date, y = country, angle = 45),
                       hjust = "left",
                       nudge_y = 0.3,
                       check_overlap = FALSE)
}


###########################
# Module 3: Mapping tools #
###########################

library(leaflet)

#' Plots filtered earthquake data on a map and labels it with a selected annotation.
#'
#' Requires a valid earthquake tibble object as an input. Errors may be caused if the
#' specified annotation column does not exist or is misspelled. The default column is
#' a predefined popup_text column, which includes a number of variables.
#'
#' @param data is a valid earthquake tibble object
#' @param annot_col is a valid column in the tibble
#'
#' @return Returns a map with earthquake data plotted on it
#'
#' @importFrom dplyr mutate
#' @importFrom leaflet leaflet addTiles addCircleMarkers

eq_map <- function(data, annot_col = "popup_text") {
  data <- data %>%
    mutate(popup_text = paste(ifelse(is.na(data$location_name), "",
                                     paste("<b>Location:</b> ", data$location_name)),
                              ifelse(is.na(data$magnitude), "",
                                     paste("<br><b>Magnitude:</b> ", data$magnitude)),
                              ifelse(is.na(data$deaths), "",
                                     paste("<br><b>Total deaths:</b> ", data$deaths)),
                              ifelse(is.na(data$date), "",
                                     paste("<br><b>Date:</b> ", data$date))))
  data2 <- data.frame(data)
  data %>%
    leaflet() %>% addTiles() %>%
    addCircleMarkers(lng = data$longitude,
                     lat = data$latitude,
                     radius = data$magnitude,
                     weight = 1, fillOpacity = 0.1,
                     popup = data2[,annot_col])
}


###############################################
# Module 3: Documentation and packaging tasks #
###############################################


