# LIBRARIES
library(tidyverse)
library(janitor)
library(stringi)

# READ GC DATA----------------
paths <- list("inputData/2024_07_10_fid_ecd_trap.xls",
              "inputData/T_2024_09_27_tcd_fid_ecd_trap.xlsx",
              "inputData/T_11_12_24_tcd_fid_ecd_trap.xlsx")

gas_dat <- map(paths, ~readxl::read_excel(.x, skip = 66) %>%
                 janitor::clean_names(.)) %>%
  dplyr::bind_rows() %>% # bind data sets
  select(sample, ch4_ppm, co2_ppm, n2o_ppm, 
         o2_ar_percent, ar_percent, o2_percent, n2_percent) %>%
  filter(!(grepl("STD", sample, fixed = FALSE)),
         !is.na(sample))

# Deal with reruns
# get a list of samples that were rerun
reruns <- gas_dat %>% 
  filter(grepl("R", sample)) %>%
  mutate(rerun = substr(sample, 1, 9)) %>% # remove the R
  pull

# filter out original injections (bad injections) and retain rerun data
gas_dat <- gas_dat %>%
  filter(!(sample %in% reruns)) %>% # exclude samples that were rerun
  # remove R from reruns
  mutate(sample = case_when(grepl("R", sample) ~ substr(sample, 1, 9), # remove the R
                            TRUE ~ sample))



# READ SAMPLE INVENTORY------
# Start with inventory of POWER samples
inventory_path <- "inputData/Copy of Exetainer Codes_02_27_2025.xlsx"
# get sheet names. "compare" is a sheet that Kit created to compare analyzed
# vs those that were submitted. It will be read in below
sheet_names <- as.list(readxl::excel_sheets(inventory_path) %>%
  .[!grepl("compare", .)]) # don't read this sheet, yet


gas_inventory_power <- map(sheet_names, 
                ~readxl::read_excel(path = inventory_path, sheet = .x, skip = 1)) %>%
  map(~janitor::clean_names(.)) %>%
  map(~select(., contains("trap_extn") & !contains("notes"))) %>%
  dplyr::bind_rows() %>% 
  pivot_longer(everything()) %>% 
  filter(!is.na(value)) %>%
  select(-name) %>%
  mutate(value = paste0(substr(value, 1, 4), ".", substr(value, 5, nchar(value))),
         value = toupper(value))

gas_inventory_compare <- readxl::read_excel(
  path = inventory_path, 
  sheet = "compare") %>%
  janitor::clean_names(.)

gas_inventory <- bind_rows(gas_inventory_power,
                           # Add Puerto Rico samples
                           gas_inventory_compare %>% 
                             filter(notes == "Puerto Rico") %>%
                             select(analyzed_from_sequence) %>%
                             rename(value = analyzed_from_sequence))

# COMPARE LIST OF ANALYZED SAMPLES TO SAMPLE INVENTORY--------------
# Analyzed samples not in POWER sample inventory?
# PS24.0557 and PS24.0565 were run but not in sample inventory
not_identified <- gas_dat %>%
  filter(!(sample %in% gas_inventory$value)) %>%
  pull(sample)

# PS24.0029 WAS INADVERTANTLY NOT RUN
# PS24.1070 IS ON DATA FILES BUT NEVER DELIVERED TO CIN (NOT ON SAMPLE TRACKING SHEETS)
# PS24.1067 IS ON DATA FILES BUT NEVER DELIVERED TO CIN (NOT ON SAMPLE TRACKING SHEETS)
# PS24.0330, PS24.0333, PS24.0334, PS24.0326, PS24.0327,PS24.0328, WERE NOT ANALYZED, OOPS
not_analyzed <- gas_inventory %>%
  filter(!(value %in% gas_dat$sample)) %>%
  pull(value)
            

# WRITE DATA TO DISK
# POWER data first
power_data <- gas_dat %>%
  filter(!(sample %in% (gas_inventory_compare %>% 
                        filter(notes == "Puerto Rico") %>%
                        pull(analyzed_from_sequence))))

write.csv(power_data, file = paste0("output/power_2024_trap_gas_", Sys.Date(), ".csv"), row.names = FALSE)


# Puerto Rico data
pr_data <- gas_dat %>%
  filter((sample %in% (gas_inventory_compare %>% 
                          filter(notes == "Puerto Rico") %>%
                          pull(analyzed_from_sequence))))

write.csv(pr_data, file = paste0("output/puerto_rico_2024_trap_gas_", Sys.Date(), ".csv"), row.names = FALSE)


