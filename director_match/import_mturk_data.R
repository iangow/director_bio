# Get data from MTurk for the first batch
# https://www.dropbox.com/s/i73m65pt46aeg7c/Batch_1790315_batch_results.csv.gz
data.dir <- "~/Dropbox/data/equilar/director_match"
data.file <- "Batch_1790315_batch_results.csv.gz" 
mturk.data <- read.csv(file.path(data.dir, data.file),
                                 stringsAsFactors=FALSE)
names(mturk.data) <- tolower(names(mturk.data))
mturk.data$agreement <- ifelse(mturk.data$agreement=="Yes", TRUE,
ifelse(mturk.data$agreement=="No", FALSE, NA))

# Push to the database
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())
dbWriteTable(pg, c("director_bio", "mturk_data"), mturk.data, 
             overwrite=TRUE, row.names=FALSE)
dbDisconnect(pg)

pg <- dbConnect(PostgreSQL())
disagreement <- dbGetQuery(pg, "")