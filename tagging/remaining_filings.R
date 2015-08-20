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

remaining_filings$file_name <-
    gsub("^.*/highlight/(\\d+)/(\\d{10})(\\d{2})(\\d{6}).*$", 
         "edgar/data/\\1/\\2-\\3-\\4.txt", remaining_filings$url)

library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("director_bio", "remaining_filings"), 
                   as.data.frame(remaining_filings),
             overwrite=TRUE, row.names=FALSE)

sql <- "ALTER TABLE director_bio.remaining_filings OWNER TO director_bio_team;"
rs <- dbGetQuery(pg, sql)

sql <- "CREATE INDEX ON director_bio.remaining_filings (file_name)"
rs <- dbGetQuery(pg, sql)

rs <- dbDisconnect(pg)

pg <- dbConnect(PostgreSQL())
rem_filings <- dbGetQuery(pg,"
    SELECT DISTINCT file_name, username, assigned_ra, c.issue_category
    FROM director_bio.bio_data
    RIGHT JOIN director_bio.remaining_filings
    USING (file_name)
    LEFT JOIN director_bio.tagging_issues AS c
    USING (file_name)")
rs <- dbDisconnect(pg)

