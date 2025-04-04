# LIBRARIES---------------
# Run from masterLibrary.R if running script in project.
library(tidyverse)
library(readxl)
library(janitor)
library(stringi)

# READ GC DATA----------------
paths <-  "L:/Lab/Lablan/GHG/GC/2018Data"

# apply function (readGC.R) to read and munge data
gc.2018 <- get_gc(paths = paths) # warnings are ok


# CHECK FOR DUPLICATES
# 0711FL41_AA4R in AIRrpt_ECD_FID_stds_UNKNOWNS_2019_04_24.xlsx
# delete for now
gc.2018 %>% janitor::get_dupes(sample) %>% print(n=Inf)
gc.2018 <- gc.2018 %>% filter(!(sample == "0711FL41_AA4R"))

# DEAL WITH RERUNS
# A few samples were flagged during first run, but were subsequently rerun.
# Reruns are identified by an 'R' at end of sample code.
# gc_fix function (rerunFunction.R) replaces flagged values with rerun values.

gc.2018 <- gc.2018 %>% 
  #filter(grepl("18R10_0130", sample)) %>% # for development
  gc_fix(.)

# WRITE FILES------------------------
# Write consolidated data back to LabLan
write.csv(gc.2018,
            file = paste0("L:/Lab/Lablan/GHG/GC/2018Data/gcMasterFile2018",
                         "updated", Sys.Date(),
                         ".csv"),
            row.names = FALSE)

