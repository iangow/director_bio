# Connect to my database
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

# Now get the data
sql <- paste(readLines("restatement_proxies.sql"), collapse="\n")
restatement_proxies <- dbGetQuery(pg, sql)

dbDisconnect(pg)
