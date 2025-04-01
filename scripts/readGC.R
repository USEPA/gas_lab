# GENERALIZED CODE FOR READING IN GC DATA

# Assumptions:
# data are stored in .xls, .xlsx
# Column headers begin in row containing "Sample.code"
# See rerunFunction.R for more assumed conventions


#paths <-  paste0(userPath, "data/gases")

get_gc <- function(paths){
  #d <-  #assign to object for code development
  fs::dir_ls(path = paths, # see above
             #regexp = 'surgeData', # file names containing this pattern
             recurse = TRUE, # look in all subdirectories
             type = "file") %>% # only retain file names, not directory names
    .[!grepl(c(".pdf|.docx|.csv"), .)] %>% # remove pdf, .docx, .csv master, and temporarly xls files
    #.[1] %>% # subset one list element for testing
    # imap will read each file in fs_path list generated above
    # the "i" in imap allows the file name (.y) to be used in function.
    purrr::imap(~read_excel(.x) %>% 
                  # add file name, but omit everything before final "/"
                  # https://stackoverflow.com/questions/65312331/extract-all-text-after-last-occurrence-of-a-special-character
                  mutate(file = sub(".*\\/", "", .y))) %>% 
    # remove empty dataframes.  Pegasus put empty Excel files in each lake
    # folder at beginning of season.  These files will be populated eventually,
    # but are causing issues with code below
    purrr::discard(~ nrow(.x) == 0) %>% 
    # format data
    #x %>% # for testing
    map(., function(x) { 
      # assign to temporary object foo.  Needed for `if` statement at end
      # of function.
      # only keep rows from Sample.code to end.  This omits standard
      # curves, graphs, etc
      x[which(x == "Sample.code"):nrow(x),] %>% 
        janitor::row_to_names(., row_number = 1) %>% # elevate first row to names
        janitor::clean_names(.) %>%
        rename_with(.cols = last_col(), ~"file") %>% # GC file name is in last column
        select(sample,
               file,
               contains("ppm"),
               contains("percent"),
               contains("flag")) %>%
        filter(!(grepl("STD", sample, ignore.case = TRUE)), # remove standards
               !(grepl("stop", sample, ignore.case = TRUE)), # remove 'stop' samples
               !(grepl("chk", sample, ignore.case = TRUE)), # remove "check" standards
               !(grepl("air", sample, ignore.case = TRUE)), # probably air standard checks
               sample != "") %>%  # exclude blank rows
        mutate(across(-c(sample, file), as.numeric), # convert to numeric
               # total = case_when(grepl("n2_percent", colnames(.)) ~ (ch4_ppm/10000) + (co2_ppm/10000) + (n2o_ppm/10000) + n2_percent + o2_percent + ar_percent,
               #                   TRUE ~ NA_real_),
               sample = str_remove(sample, '\\.'), # remove "." from exetainer codes
               #sample = str_remove(sample, '\\_'), # remove "_" from exetainer codes
               sample = toupper(sample)) %>% # sg -> SG, r ->R (for rerun samples)
        # "flag" and "analyte" are in different orders across the spreadsheets.
        # Need to make uniform
        # case_when works even if the specified column isn't present
        # https://stackoverflow.com/questions/68965823/rename-only-if-field-exists-otherwise-ignore
        rename_with(
          ~case_when(
            . == "ch4_flag" ~ "flag_ch4",
            . ==  "co2_flag" ~ "flag_co2",
            . == "n2o_flag" ~ "flag_n2o",
            . == "n2_flag" ~ "flag_n2",
            . == "ar_flag" ~ "flag_ar",
            . == "o2_flag" ~ "flag_o2",
            TRUE ~ .))
      
    }) %>%
    map_dfr(., identity) # rbinds into one df
}

# apply function
#gc <- get_gc(paths = paths) # warnings are ok
