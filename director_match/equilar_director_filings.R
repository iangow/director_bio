library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())
sql <- paste(readLines("director_match/equilar_director_filings.sql"), collapse="\n")
equilar_director_filings <- dbGetQuery(pg, sql)
rs <- dbDisconnect(pg)



