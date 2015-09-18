# Connect to the database, run a query to get data, and disconnect ----
library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())

rs <- dbGetQuery(pg, "SET work_mem='3GB';")

# Load SQL from a separate file.
sql <- paste(readLines("tagging/missing_bios.sql"), collapse="\n")
# Type cat(sql) to see what the loaded SQL looks like.

# Query takes about 20 seconds to run.
missing_bios <- dbGetQuery(pg, sql)
rs <- dbDisconnect(pg)

# In many cases, there is no `term_end_date` on Equilar. So we might need to 
# dig a little further for a sample of these cases.
table(is.na(missing_bios$term_end_date))
closer_look_1 <- subset(missing_bios, is.na(term_end_date))
View(closer_look_1)
library(xlsx)
write.xlsx(closer_look_1, "missing_bios_1.xlsx", row.names=FALSE)


# There are other cases, where the term end date is more than 60 days after
# the filing was made. These also probably warrant a little digging.
table(missing_bios$term_end_date >missing_bios$date_filed + 60)
closer_look_2 <- subset(missing_bios, term_end_date > date_filed + 60)
View(closer_look_2)
library(xlsx)
write.xlsx(closer_look_2, "missing_bios_2.xlsx", row.names=FALSE)
