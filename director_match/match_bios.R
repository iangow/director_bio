# Connect to my database
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

# Now get the data
sql <- paste(readLines("match_bios.sql"), collapse="\n")
match_bios <- dbGetQuery(pg, sql)

dbDisconnect(pg)

write.csv(match_bios, "data/match_bios.csv")
