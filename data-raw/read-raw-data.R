require(readr)
raw_data <- readr::read_tsv("signif.txt")
devtools::use_data(raw_data)
