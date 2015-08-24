
# Get data from Google Sheets document ----
library(googlesheets)
library(readr)
library(dplyr)

# As a one-time thing per user and machine, you will need to run gs_auth()
# to authorize googlesheets to access your Google Sheets.

gs <- gs_key("1z8x9Owt_ztjCukYEpkc5pDD2vPOQJvrTA9UvW90cgmo")
gs_read(gs, ws = "Batch 1") %>%
    filter(needs_retagging) %>%
    select(url, comments) %>% 
    write_csv("~/Google Drive/director_bio/bio_tagging/retag.csv")
# I then go to drive.google.com, open the CSV as a Google Sheet, then
# copy the data into the appropriate place on the "filing_list" sheet in the Google Sheet with key
# 1B58Z9MEZsV69MFLIBv8DEv3sddScBYAKY2yM4ggihVo