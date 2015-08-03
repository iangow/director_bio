sql <- paste(readLines("tagging/names_needing_distinction.sql"),
             collapse="\n")
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

names_need_distinct <- dbGetQuery(pg, sql)

dbDisconnect(pg)

with(names_need_distinct, 
     table(username, flagged))
