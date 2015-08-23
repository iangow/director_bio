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

# Flag cases without bios for re-tagging
re_tag <- unique(subset(strikethrough, is.na(clean_bio), select=url))
write.csv(re_tag, "~/Google Drive/director_bio/bio_tagging/re_tag.csv", 
          row.names = FALSE)
# I manually added these bios to the "remaining filing" sheet with a note 
# to re-tag them.

