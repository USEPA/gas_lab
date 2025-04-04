bind_rows(gc.2018, gc.2020, gc.2021, gc.2022, gc.2023) %>%
  filter(!grepl("ACT", sample)) %>%
  pivot_longer(-c(sample, file)) %>%
  filter(value < 0) %>%
  arrange(sample, name) %>%
  #print(n=Inf)
  write.table(file = "output/negative_values.xls", row.names = F)
