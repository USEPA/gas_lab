
# READ GC DATA----------------
# Read individual files.

paths <-  "L:/Lab/Lablan/GHG/GC/2023Data"

# apply function
gc.2023 <- get_gc(paths = paths) %>%
  mutate(sample = gsub("SS", "SG", sample, ignore.case = TRUE))
  # change SS to SG


# CHECK FOR DUPLICATES
# SG230086 repeated in Air_2023_10_25_FID_ECD_STD_UNK.xlsx / DG_2023_10_26_FID_ECD_STD_UNK.xlsx
# SG230087 repeated in Air_2023_10_25_FID_ECD_STD_UNK.xlsx
# SG230088 repeated in Air_2023_10_25_FID_ECD_STD_UNK.xlsx, DG_2023_10_26_FID_ECD_STD_UNK.xlsx
# SG230153 repeated in Air_2023_10_25_FID_ECD_STD_UNK.xlsx (duplicate 0153 exetainers sent to ADA in 2022 and 2023)
# SG230498 repeated in DG_2023_10_26_FID_ECD_STD_UNK.xlsx, T_2023_11_14_tcd_fid_ecd_trap.xls

# strip out for now [4/1/25]
gc.2023 %>% janitor::get_dupes(sample) %>% print(n=Inf)
gc.2023 <- gc.2023 %>% filter(!(sample %in% c("SG230086", "SG230087", "SG230088", 
                                              "SG230153", "SG230498")))

# DEAL WITH RERUNS
# A few samples were flagged during first run, but were subsequently rerun.
# Reruns are identified by an 'R' at end of sample code.
# gc_fix function replaces flagged values with rerun values.

gc.2023 <- gc.2023 %>% 
  gc_fix(.)

# WRITE FILES------------------------
# Write consolidated data back to LabLan
write.csv(gc.2023,
            file = paste0("L:/Lab/Lablan/GHG/GC/2023Data/gcMasterFile2023",
                         "updated", Sys.Date(),
                         ".csv"),
            row.names = FALSE)


# write consolidated data to SuRGE repo
write.csv(gc.2023,
          file = paste0("C:/Users/JBEAULIE/OneDrive - Environmental Protection Agency (EPA)/gitRepository/SuRGE/SuRGE_Sharepoint/data/gases/2023Data/",
                        "gcMasterFile2023updated", Sys.Date(),
                        ".csv"),
          row.names = FALSE)
