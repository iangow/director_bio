# Get data from Google Sheets document ----
library(googlesheets)

# As a one-time thing per user and machine, you will need to run gs_auth()
# to authorize googlesheets to access your Google Sheets.

gs <- gs_key("1B58Z9MEZsV69MFLIBv8DEv3sddScBYAKY2yM4ggihVo")

library(dplyr)
bio_tagging_issues <- gs_read(gs, ws = "Issues") 

# As a single filing can be affected by multiple issues, I asked the RAs to 
# separate multiple issues (where applicable) using semi-colons.
# I then store these as lists in R.
bio_tagging_issues$issue_category <- strsplit(bio_tagging_issues$issue_category, ";")

# Look at the distribution of issues.
issue_tab <- table(unlist(bio_tagging_issues$issue_category))
issue_tab[order(issue_tab, decreasing = TRUE)]

table(is.na(bio_tagging_issues$issue_category))
