# LIBRARIES---------------
# Run from masterLibrary.R if running script in project.
library(tidyverse)
library(readxl)
library(janitor)
library(stringi)

# READ GC DATA----------------
paths <-  "L:/Lab/Lablan/GHG/GC/2020Data"

# apply function (readGC.R) to read and munge data
gc.2020 <- get_gc(paths = paths) %>% # warnings are ok
  mutate(sample = sub("\\_R10+$", "", sample)) # remove "R10" from the END of sample code.


# CHECK FOR DUPLICATES
# SG200355 in Air_2021_01_19_FID_ECD_STD_UNK.xlsx, DG_2020_11_19_FID_ECD_STD_UNK.xlsx
# delete for now
gc.2020 %>% janitor::get_dupes(sample) %>% print(n=Inf)
gc.2020 <- gc.2020 %>% filter(!(sample == "SG200355"))

# DEAL WITH RERUNS
# A few samples were flagged during first run, but were subsequently rerun.
# Reruns are identified by an 'R' at end of sample code.
# gc_fix function (rerunFunction.R) replaces flagged values with rerun values.

gc.2020 <- gc.2020 %>% 
  #filter(grepl("SG200752", sample)) %>% # for development
  gc_fix(.)

# WRITE FILES------------------------
# Write consolidated data back to LabLan
write.csv(gc.2020, 
          file = paste0("L:/Lab/Lablan/GHG/GC/2020Data/gcMasterFile2020",
                        "updated", Sys.Date(),
                        ".csv"),
          row.names = FALSE)



