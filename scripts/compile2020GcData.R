
# READ GC DATA----------------
paths <-  "L:/Lab/Lablan/GHG/GC/2020Data"

# apply function (readGC.R) to read and munge data
gc.2020 <- get_gc(paths = paths) %>% # warnings are ok
  # The lab received duplicate exetainer codes from CIN and R10 in 2020.
  # Only one sample for each duplicated code was analyzed. The lab that the
  # sample originated from is indicated with a "_R10" or "_CIN" appended to the 
  # end of the sample code in the excel spreadsheets. This information
  # is hardcoded in readGc.R in the SuRGE repo and is not needed from the Excel
  # spreadsheets. Strip the "_R10" or "_CIN" from the sample codes 
  mutate(sample = sub("\\_R10+$", "", sample), # remove "_R10" from the END of sample code
         sample = sub("\\_CIN+$", "", sample)) # remove "_CIN" from the END of sample code


# CHECK FOR DUPLICATES
# SG200355 in Air_2021_01_19_FID_ECD_STD_UNK.xlsx, DG_2020_11_19_FID_ECD_STD_UNK.xlsx
# should be in air, and the air sample looks like air. The sample in DG must be
# a sample ID mix up. Delete the one from DG file
gc.2020 %>% janitor::get_dupes(sample) %>% print(n=Inf)
gc.2020 <- gc.2020 %>% filter(!(sample == "SG200355" &
                                file == "DG_2020_11_19_FID_ECD_STD_UNK.xlsx"))

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

# write consolidated data to SuRGE repo
write.csv(gc.2020,
          file = paste0("C:/Users/JBEAULIE/OneDrive - Environmental Protection Agency (EPA)/gitRepository/SuRGE/SuRGE_Sharepoint/data/gases/2020Data/",
                        "gcMasterFile2020updated", Sys.Date(),
                        ".csv"),
          row.names = FALSE)

