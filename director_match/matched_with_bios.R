# system("psql -f director_match/match_directors.sql")
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())
sql <- paste(readLines("director_match/matched_with_bios.sql"), collapse="\n")
matched_with_bios <- dbGetQuery(pg, sql)
rs <- dbDisconnect(pg)

clean_bio <- function(bio) {
    gsub("\\s+", " ", bio)
}

matched_with_bios$bio <- unlist(lapply(matched_with_bios$bio, clean_bio))
matched_with_bios$matched_bio <- unlist(lapply(matched_with_bios$matched_bio, clean_bio))
# with(equilar_director_filings, table(term_end_date < date_filed, useNA="ifany"))
