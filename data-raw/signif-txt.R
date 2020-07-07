## code to prepare `signif.txt` dataset goes here
require(readr)
raw_data <- readr::read_tsv("signif.txt")
usethis::use_data(raw_data, overwrite = TRUE)
