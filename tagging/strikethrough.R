sql <- paste(readLines("tagging/strikethrough.sql"),
             collapse="\n")
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

strikethrough <- dbGetQuery(pg, sql)

dbDisconnect(pg)

clean_bio <- function(bio) {
    new_text <- gsub("\\n", " ", bio)
    new_text <- gsub("\\s+", " ", new_text)
    new_text
}


strikethrough$clean_bio <- 
    unlist(lapply(strikethrough$bio, clean_bio))