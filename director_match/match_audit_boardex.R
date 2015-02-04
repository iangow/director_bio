library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())
sql <- paste(readLines("director_match/match_audit_boardex.sql"), collapse="\n")
audit_boardex <- dbGetQuery(pg, sql)

# Construct hyperlink
audit_boardex$hyperlink <-
    paste0("http://www.sec.gov/Archives/",
           gsub("(\\d{10})-(\\d{2})-(\\d{6})\\.txt", "\\1\\2\\3", 
                audit_boardex$file_name))
write.csv(audit_boardex,
          file="~/Google Drive/director_bio/audit_boardex.csv",
          row.names = FALSE)
