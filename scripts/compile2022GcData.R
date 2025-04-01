# LIBRARIES---------------
# Run from masterLibrary.R if running script in project.
library(tidyverse)
library(readxl)
library(janitor)
library(stringi)

# READ GC DATA----------------
# Read individual files.

paths <-  "L:/Lab/Lablan/GHG/GC/2022Data"

# apply function
gc.2022 <- get_gc(paths = paths) # warnings are ok


# CHECK FOR DUPLICATES
# SG220153 repeated in 2022_08_11_dissolved gas.xlsx
# strip out for now [4/1/25]
gc.2022 %>% janitor::get_dupes(sample) %>% print(n=Inf)
gc.2022 <- gc.2022 %>% filter(!(sample == "SG220153"))

# DEAL WITH RERUNS
# A few samples were flagged during first run, but were subsequently rerun.
# Reruns are identified by an 'R' at end of sample code.
# gc_fix function replaces flagged values with rerun values.

gc.2022 <- gc.2022 %>% 
  gc_fix(.)

# WRITE FILES------------------------
# Write consolidated data back to LabLan
write.csv(gc.2022, 
            file = paste0("L:/Lab/Lablan/GHG/GC/2022Data/gcMasterFile2022",
                         "updated", Sys.Date(),
                         ".csv"),
            row.names = FALSE)

