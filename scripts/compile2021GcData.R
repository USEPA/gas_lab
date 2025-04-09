
# READ GC DATA----------------
paths <-  "L:/Lab/Lablan/GHG/GC/2021Data"

# apply function (readGC.R) to read and munge data
gc.2021 <- get_gc(paths = paths) 

# CHECK FOR DUPLICATES
# none
gc.2021 %>% janitor::get_dupes(sample) %>% print(n=Inf)


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


# write consolidated data to SuRGE repo
write.csv(gc.2021,
          file = paste0("C:/Users/JBEAULIE/OneDrive - Environmental Protection Agency (EPA)/gitRepository/SuRGE/SuRGE_Sharepoint/data/gases/2021Data/",
                        "gcMasterFile2021updated", Sys.Date(),
                        ".csv"),
          row.names = FALSE)

