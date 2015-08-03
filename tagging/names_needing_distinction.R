sql <- paste(readLines("tagging/names_needing_distinction.sql"),
             collapse="\n")
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

names_need_distinct <- dbGetQuery(pg, sql)

dbDisconnect(pg)

with(names_need_distinct, 
     table(username, flagged))

clean_bio <- function(bio) {
    new_text <- gsub("\\n", " ", bio)
    new_text <- gsub("\\s+", " ", new_text)
    new_text
}

names_need_distinct$bio <- 
    unlist(lapply(names_need_distinct$bio, clean_bio))

# Upload data to Google Sheets.
xlsx::write.xlsx(names_need_distinct, "data/names_need_distinct.xlsx", row.names = FALSE)
names_need_distinct_gs <- gs_upload("data/names_need_distinct.xlsx")
# gs_read_listfeed(names_need_distinct_gs)
file.remove("data/names_need_distinct.xlsx")

