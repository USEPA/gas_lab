# LIBRARIES
library(tidyverse)
library(janitor)
library(stringi)

# READ GC DATA----------------
paths <- list("inputData/2024_12_11_AIR.xlsx",
              "inputData/2024_12_11_DG.xlsx")
skip <- list(53, # air file
             95 # dissolved gas file
             )

air_dg_dat <- map2(.x = paths, .y = skip, ~readxl::read_excel(.x, skip = .y) %>%
                 janitor::clean_names(.)) %>%
  dplyr::bind_rows() %>% # bind data sets
  select(sample, ch4_ppm, co2_ppm, n2o_ppm) %>%
  filter(!(grepl("STD", sample, fixed = FALSE)),
         !is.na(sample))


# WRITE DATA TO DISK
# Only Puerto Rico in 2024
write.csv(air_dg_dat, file = paste0("output/puerto_rico_2024_air_dg_", Sys.Date(), ".csv"), row.names = FALSE)


