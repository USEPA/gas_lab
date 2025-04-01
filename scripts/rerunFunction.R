# This function will replace flagged data from the GC with values
# from a reanalysis of same sample. Column naming conventions are
# specified in example df below. 
# The code retains all non-flagged value from first injection.
# Assumes Rerun samples have "R" at end of sample code.



# Function assumes data are presented as:
x <- tribble(
  ~sample, # character string, terminal R if a rerun
  ~file, # GC file name
  ~ch4_ppm, ~co2_ppm, ~n2o_ppm, ~n2_percent, ~o2_percent, ~ar_percent, ~ar_o2_percent, 
  ~flag_n2o, ~flag_co2, ~flag_ch4, ~flag_n2, ~flag_o2, ~flag_ar, ~flag_ar_o2,
  
  # ORIGINAL INJECTION WITH FLAGS WITH A RERUN-------
  # example original sample with flags for ch4 and co2
  "sample1", # example sample code
  "trap_1.xlsx", # example file name
  127, 543, .341, 78.7, 21.3,	0.9, NA, # gas concentrations
  1,   1,   NA,   NA,   NA,  NA,   NA, # flags
  
  # example rerun with no flags
  "sample1R", # example sample code
  "trap_1_rerun.xlsx", # example sample type
  135, 532, .331, 79.1, 21.1,	0.8, NA, # gas concentrations
  NA,   NA,   NA,   NA,   NA,  NA,   NA, # flags
  
  # SAMPLE FLAGGED BUT NEVER RERUN--------
  # must return NA for flagged value
  # example original sample with flags for ch4 and co2
  "sample2", # example sample code
  "dg_1.xlsx", # example sample type
  1130, 1200, .112, 52.3, 4.2,	0.6, NA, # gas concentrations
  1,   1,   NA,   NA,   NA,  NA,   NA, # flags
  
  # WE HAVE A RERUN BUT NOT FIRST INJECTION------
  # example original sample with flags for ch4 and co2
  "sample3R", # example sample code
  "foo.xlsx", # example sample type
  1262, 125, .453, 48.2, 15,	0.3, NA, # gas concentrations
  NA,   NA,   NA,   NA,   NA,  NA,   NA, # flags
)

# Function replaces flagged values with rerun data.
# accommodates the presence/absence of all potential analytes
# also accomodates flagged rerun values. Probably never see that
# but possible. Does not accomodate multiple rerun values.
gc_fix <- function(x) {
  
  # MAKE SURE COLUMN NAMES ARE FORMATTED CORRECTLY
  # ASSUME janitor::clean_names FORMAT
  names_check <- colnames(x) %in% c("sample", "file", "ch4_ppm", "co2_ppm", "n2o_ppm",
                                    "n2_percent", "o2_percent", "ar_percent", "ar_o2_percent",
                                    "flag_n2o", "flag_co2", "flag_ch4", "flag_n2", "flag_o2",
                                    "flag_ar", "flag_ar_o2")
  
  if(all(names_check == TRUE)) {
    print("All data column names are properly formatted")
  }
  
  if(any(names_check != TRUE)) {
    print(paste0(colnames(x)[!names_check], "are not recognized column names. Did you format per the janitor::clean_names convention?"))
  }
  
  
  x <- x %>% 
    # move "R" from the sample code to new column
    mutate(rerun = case_when(stri_sub(sample, -1) == "R" ~ "R", #R if rerun
                             TRUE ~ "F"), # F (first run) if not
           
           # now we can strip the "R" from the sample code
           sample = case_when(stri_sub(sample, -1) == "R" ~ str_sub(sample, end = -2),
                              TRUE ~ sample)) %>%
    pivot_longer(!c(sample, rerun, file)) %>%
    
    # now we need to adopt the same file name for samples that have both a
    # First and Rerun injection. This is required for pivot_wider to collapse
    # the records into a single row.
    group_by(sample) %>% # First and Rerun samples have identical sample values
    # collapse distinct file names into a string
    mutate(file = paste(unique(file), collapse = ",")) %>%
    
    # pivot wider to collapse First and Rerun injections into a single row per sample
    pivot_wider(names_from = c(name, rerun), values_from = value) %>%
    
    # occasionally have record of a Rerun without a First injection. We must
    # flag the First injection values (even though they don't exist) or the
    # code will report NA for all concentrations.
    # using if statement to accommodate whatever collection of analytes are
    # present in data
    mutate(
      flag_n2o_F = if("flag_n2o" %in% colnames(x)) {
        case_when(is.na(n2o_ppm_F) ~ 1, # if no data from First injection, 1
                  TRUE ~ flag_n2o_F)
      }) %>% # close if statement and mutate
    
    mutate(
      flag_co2_F =  if("flag_co2" %in% colnames(x)) {
        case_when(is.na(co2_ppm_F) ~ 1, # if no data from First injection, 1
                  TRUE ~ flag_co2_F)
      }) %>% # close if statement and mutate
    
    mutate(
      flag_ch4_F = if("flag_ch4" %in% colnames(x)) {
        case_when(is.na(ch4_ppm_F) ~ 1, # if no data from First injection, 1
                  TRUE ~ flag_ch4_F)
      }) %>% # close if statement and mutate
    
    mutate(
      flag_n2_F = if("flag_n2" %in% colnames(x)) {
        case_when(is.na(n2_percent_F) ~ 1, # if no data from First injection, 1
                  TRUE ~ flag_n2_F)
      }) %>% # close if statement and mutate
    
    mutate(
      flag_o2_F = if("flag_o2" %in% colnames(x)) {
        case_when(is.na(o2_percent_F) ~ 1, # if no data from First injection, 1
                  TRUE ~ flag_o2_F)
      }) %>% # close if statement and mutate
    
    mutate(
      flag_ar_F = if("flag_ar" %in% colnames(x)) {
        case_when(is.na(ar_percent_F) ~ 1, # if no data from First injection, 1
                  TRUE ~ flag_ar_F)
      }) %>% # close if statement and mutate
    
    mutate(
      flag_ar_o2_F = if("flag_ar_o2" %in% colnames(x)) {
        case_when(is.na(ar_o2_percent_F) ~ 1, # if no data from First injection, 1
                  TRUE ~ flag_ar_o2_F)
      }) %>% # close if statement and mutate
    
    # get correct ch4 concentration   
    mutate(
      ch4_ppm = if("ch4_ppm" %in%  colnames(x)) {
        case_when(
          # if First is not flag, then use First value
          is.na(flag_ch4_F) ~ ch4_ppm_F, 
          # if First is flagged but Rerun isn't, then rerun
          # this condition also returns NA if First was flagged but 
          # sample was not Rerun
          !is.na(flag_ch4_F) & is.na(flag_ch4_R) ~ ch4_ppm_R,
          # if both First and Rerun are flagged, then NA
          !is.na(flag_ch4_F) & !is.na(flag_ch4_R) ~ NA_real_,
          # error code
          TRUE ~ 999999999)
      }) %>% # close if statement and mutate
    
    # get correct co2 concentration
    mutate(
      co2_ppm = if("co2_ppm" %in%  colnames(x)) {
        case_when(
          # if First is not flag, then use First value
          is.na(flag_co2_F) ~ co2_ppm_F, 
          # if First is flagged but Rerun isn't, then rerun
          !is.na(flag_co2_F) & is.na(flag_co2_R) ~ co2_ppm_R,
          # if both First and Rerun are flagged, then NA
          !is.na(flag_co2_F) & !is.na(flag_co2_R) ~ NA_real_,
          # error code
          TRUE ~ 999999999)
      }) %>% # close if statement and mutate
    
    # get correct n2o concentration
    mutate(
      n2o_ppm = if("n2o_ppm" %in%  colnames(x)) {
        case_when(
          # if First is not flag, then use First value
          is.na(flag_n2o_F) ~ n2o_ppm_F, 
          # if First is flagged but Rerun isn't, then rerun
          !is.na(flag_n2o_F) & is.na(flag_n2o_R) ~ n2o_ppm_R,
          # if both First and Rerun are flagged, then NA
          !is.na(flag_n2o_F) & !is.na(flag_n2o_R) ~ NA_real_,
          # error code
          TRUE ~ 999999999)
      }) %>% # close if statement and mutate
    
    # get correct n2 concentration
    mutate(
      n2_percent = if("n2_percent" %in%  colnames(x)) {
        case_when(
          # if First is not flag, then use First value
          is.na(flag_n2_F) ~ n2_percent_F, 
          # if First is flagged but Rerun isn't, then rerun
          !is.na(flag_n2_F) & is.na(flag_n2_R) ~ n2_percent_R,
          # if both First and Rerun are flagged, then NA
          !is.na(flag_n2_F) & !is.na(flag_n2_R) ~ NA_real_,
          # error code
          TRUE ~ 999999999)
      }) %>% # close if statement and mutate
    
    # get correct O2 concentration
    mutate(
      o2_percent = if("o2_percent" %in%  colnames(x)) {
        case_when(
          # if First is not flag, then use First value
          is.na(flag_o2_F) ~ o2_percent_F, 
          # if First is flagged but Rerun isn't, then rerun
          !is.na(flag_o2_F) & is.na(flag_o2_R) ~ o2_percent_R,
          # if both First and Rerun are flagged, then NA
          !is.na(flag_o2_F) & !is.na(flag_o2_R) ~ NA_real_,
          # error code
          TRUE ~ 999999999)
      }) %>% # close if statement and mutate
    
    # get correct ar concentration
    mutate(ar_percent = if("ar_percent" %in%  colnames(x)) {
      case_when(
        # if First is not flag, then use First value
        is.na(flag_ar_F) ~ ar_percent_F, 
        # if First is flagged but Rerun isn't, then rerun
        !is.na(flag_ar_F) & is.na(flag_ar_R) ~ ar_percent_R,
        # if both First and Rerun are flagged, then NA
        !is.na(flag_ar_F) & !is.na(flag_ar_R) ~ NA_real_,
        # error code
        TRUE ~ 999999999)
    }) %>% # close if statement and mutate
    
    # get correct O2+ar concentration
    mutate(ar_o2_percent = if("ar_o2_percent" %in%  colnames(x)) {
      case_when(
        # if First is not flag, then use First value
        is.na(flag_ar_o2_F) ~ ar_o2_percent_F, 
        # if First is flagged but Rerun isn't, then rerun
        !is.na(flag_ar_o2_F) & is.na(flag_ar_o2_R) ~ ar_o2_percent_R,
        # if both First and Rerun are flagged, then NA
        !is.na(flag_ar_o2_F) & !is.na(flag_ar_o2_R) ~ NA_real_,
        # error code
        TRUE ~ 999999999)
    }) %>% # close if statemment and mutate
    select_if(names(.) %in% c("sample", "file", "ch4_ppm", "co2_ppm", "n2o_ppm", 
                              "n2_percent", "o2_percent", "ar_percent", 
                              "ar_o2_percent"))
  
  # CHECK FOR ERROR FLAGS
  if(any(x == 999999999, na.rm = TRUE)) { # ignore missing analytes
    print("STOP, DATASET CONTAINS 999999999. MUST BE AN ERROR.")
  }
  
  return(x)
}

#gc_fix(x)
#gc_fix(gc.all)
