# Connect to my database
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

# Now get the data
sql <- paste(readLines("sec_invest.sql"), collapse="\n")
sec_invest <- dbGetQuery(pg, sql)

dbDisconnect(pg)