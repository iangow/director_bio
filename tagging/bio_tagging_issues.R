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
text_to_json <- function(string) {
    library(jsonlite)
    a_list <- strsplit(string, ";")
    toJSON(a_list[[1]])
}

bio_tagging_issues$issue_category <- 
    unlist(lapply(bio_tagging_issues$issue_category, text_to_json))

# Look at the distribution of issues.
issue_tab <- table(unlist(bio_tagging_issues$issue_category))
issue_tab[order(issue_tab, decreasing = TRUE)]

table(is.na(bio_tagging_issues$issue_category))

# Push data to PostgreSQL ----
bio_tagging_issues <- as.data.frame(bio_tagging_issues)
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("director_bio", "tagging_issues"), bio_tagging_issues,
             overwrite=TRUE, row.names=FALSE)

