# system("psql -f director_match/match_directors.sql")
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())
sql <- paste(readLines("director_match/equilar_director_filings.sql"), collapse="\n")
equilar_director_filings <- dbGetQuery(pg, sql)
rs <- dbDisconnect(pg)

# with(equilar_director_filings, table(term_end_date < date_filed, useNA="ifany"))