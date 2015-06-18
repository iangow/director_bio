sql <- paste(readLines("director_match/equilar_director_filings_simple.sql"), collapse="\n")

library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())
equilar_director_filings <- dbGetQuery(pg, sql)
rs <- dbDisconnect(pg)

readr::write_csv(equilar_director_filings, "data/director_filings.csv")
system("gzip data/director_filings.csv")