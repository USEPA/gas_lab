# LIBRARIES---------------
# Run from masterLibrary.R if running script in project.
library(tidyverse)
library(readxl)
library(janitor)
library(stringi)

# READ GC DATA----------------
paths <-  "L:/Lab/Lablan/GHG/GC/2021Data"

# apply function (readGC.R) to read and munge data
gc.2021 <- get_gc(paths = paths) 

# CHECK FOR DUPLICATES
# SG211109 in Air_2021_10_08_FID_ECD_STD_UNK.xlsx, T_21_11_01_ECD_FID_TCD_STD_UNK.xlsx
# delete for now
gc.2021 %>% janitor::get_dupes(sample) %>% print(n=Inf)
gc.2021 <- gc.2021 %>% filter(!(sample == "SG211109"))

# DEAL WITH RERUNS
# A few samples were flagged during first run, but were subsequently rerun.
# Reruns are identified by an 'R' at end of sample code.
# gc_fix function (rerunFunction.R) replaces flagged values with rerun values.

gc.2021 <- gc.2021 %>% 
  #filter(grepl("SG210043", sample)) %>% # for development
  gc_fix(.)

# WRITE FILES------------------------
# Write consolidated data back to LabLan
write.csv(gc.2021, 
          file = paste0("L:/Lab/Lablan/GHG/GC/2021Data/gcMasterFile2021",
                        "updated", Sys.Date(),
                        ".csv"),
          row.names = FALSE)




