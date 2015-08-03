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

names_need_distinct$clean_bio <- 
    unlist(lapply(names_need_distinct$bio, clean_bio))