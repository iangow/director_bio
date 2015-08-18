# Connect to the database, run a query to get data, and disconnect ----
library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())

# Load SQL from a separate file.
sql <- paste(readLines("tagging/bios_wrong_place.sql"), collapse="\n")
# Type cat(sql) to see what the loaded SQL looks like.

bios_wrong_place <- dbGetQuery(pg, sql)
rs <- dbDisconnect(pg)

# Now start looking at the bios for these cases ---
View(bios_wrong_place)

# There are no "missing" bios ...
table(is.na(bios_wrong_place$bio))

# There is one empty bio
table(bios_wrong_place$bio=="")

# Let's look at it ...
subset(bios_wrong_place, bio=="")

# I can look at the page indicated in the `uri` field for this case,
# "John Skolds"
browseURL("http://hal.marder.io/highlight/753308/000119312513143987")

# Hmm. It seems the bio is there and has been tagged. So let's take a look ...
subset(bios_wrong_place, grepl("Skolds", director))
# Based on the above, it seems that Regina tagged the bio in multiple steps. 
# This is fine (we just need to make sure to piece these back together later on).

# Honestly, all the bios with this tagging issue seem fine. Row 807 (for me)
# seems a little odd. I can look at all columns of this row thus ...
bios_wrong_place[807, ]

# ... or look at just the bio like this (the `cat` function) prints a little
# cleaner than simply typing `bios_wrong_place$bio[807]`.
cat(bios_wrong_place$bio[807])
