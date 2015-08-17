# Get data from Google Sheets document ----
library(googlesheets)

# As a one-time thing per user and machine, you will need to run gs_auth()
# to authorize googlesheets to access your Google Sheets.

gs <- gs_key("1B58Z9MEZsV69MFLIBv8DEv3sddScBYAKY2yM4ggihVo")

library(dplyr)
bio_tagging_issues <- gs_read(gs, ws = "Issues") 
bio_tagging_issues <- as.data.frame(bio_tagging_issues)
bio_tagging_issues$file_name <- 
    gsub("http://www.sec.gov/Archives/edgar/data/(\\d+)/(\\d{10})(\\d{2})(\\d{6})", 
         "edgar/data/\\1/\\2-\\3-\\4.txt", bio_tagging_issues$url_filing)

# As a single filing can be affected by multiple issues, I asked the RAs to 
# separate multiple issues (where applicable) using semi-colons.
# I then store these as lists in R.
text_to_list <- function(string) {
    strsplit(string, ";")[[1]]
}

bio_tagging_issues$issue_category_alt <- 
    lapply(bio_tagging_issues$issue_category, text_to_list)

# Look at the distribution of issues.
issue_tab <- table(unlist(bio_tagging_issues$issue_category_alt))
issue_tab[order(issue_tab, decreasing = TRUE)]

table(is.na(bio_tagging_issues$issue_category))

# Push data to PostgreSQL ----
list_to_json <- function(list) {
    library(jsonlite)
    toJSON(list[[1]])
}

bio_tagging_issues$issue_category_alt <- 
    unlist(lapply(bio_tagging_issues$issue_category_alt, list_to_json))

bio_tagging_issues$issue_category_alt <- 
    gsub("\\[", "{", bio_tagging_issues$issue_category_alt)

bio_tagging_issues$issue_category_alt <- 
    gsub("\\]", "}", bio_tagging_issues$issue_category_alt)


bio_tagging_issues <- as.data.frame(bio_tagging_issues)
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("director_bio", "tagging_issues"), bio_tagging_issues,
             overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "
    ALTER TABLE director_bio.tagging_issues 
        ALTER issue_category_alt TYPE text[] USING issue_category_alt::text[]")

sql <- "
    SELECT unnest(issue_category_alt) AS issue_category, count(*)
    FROM director_bio.tagging_issues 
    GROUP BY unnest(issue_category_alt) 
    ORDER BY count(*) DESC;"

dbGetQuery(pg, sql)

rs <- dbDisconnect(pg)