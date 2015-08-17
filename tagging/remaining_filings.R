# Get data from Google Sheets document ----
library(googlesheets)

# As a one-time thing per user and machine, you will need to run gs_auth()
# to authorize googlesheets to access your Google Sheets.

gs <- gs_key("1B58Z9MEZsV69MFLIBv8DEv3sddScBYAKY2yM4ggihVo")

library(dplyr)
remaining_filings <- gs_read(gs, ws = "filing_list") 
table(is.na(remaining_filings$assigned_ra))
table(remaining_filings$assigned_ra, useNA="ifany")
with(remaining_filings, table(is.na(issue_category), assigned_ra))
