


# CALIBRATION CURVE CORRECTION--------------------------
# ## NOT YET IMPLIMENTED IN 2018 (JB 18-20-18)
# # Correct low level CH4 and CO2 for bias in calibration standard.
# # Determined by comparing PraxAir stds used for calibration curve
# # to Sarah's high quality eddy flux standards from AirGas.  Certificate of
# # analysis on file.  
# 
# gc.std <- read_excel("L:/Lab/Lablan/GHG/GC/2017Data/PRAXair_vs_SARAH_STD.xlsx", 
#                     trim_ws = TRUE, skip=50)
# # simplify names
# names(gc.std) = gsub(pattern = c("\\(| |#|)|/|%|-|\\+"), replacement = ".", 
#                      x = names(gc.std))
# 
# # Estimated CO2 concentration of Airgas std based on Praxair std curve
# meanCo2 <- filter(gc.std, grepl("CO2", Sample)) %>%
#   select(CO2..ppm.) %>%
#   summarise(meanCo2 = mean(CO2..ppm.)) %>% as.numeric
# 
# biasCo2 <- meanCo2 / 507.3 # +/- 1% certified concentration
# 
# 
# # Estimated CH4 concentration of Airgas std based on Praxair std curve
# meanCh4 <- filter(gc.std, grepl("CH4", Sample)) %>%
#   select(CH4..ppm.) %>%
#   summarise(meanCH4 = mean(CH4..ppm.)) %>% as.numeric
# 
# biasCh4 <- meanCh4 / 2.047 # +/- 1% certified concentration
# 
# # Corrections apply to low CO2 and CH4.
# gc.all <- mutate(gc.all, 
#                  ch4.ppm = ifelse(ch4.ppm < 8,
#                                   ch4.ppm * (1/biasCh4),
#                                   ch4.ppm),
#                  co2.ppm = ifelse(co2.ppm < 510,
#                                   co2.ppm * (1/biasCo2),
#                                   co2.ppm))