# Code to get and analyze data from ElasticSearch store.
#
get_es_data <- function() {
# Function to get data from ElasticSearch
# I'm not sure how robust this is. Probably best to only run this when the data
# are not changing. Not clear how robust this is in getting each record only
# once and getting all records.

    library(jsonlite)
    library(curl)

    MAX_ROWS <- 200
    temp <- fromJSON("http://annotator-store.marder.io/search?limit=1")

    i_max <- as.integer(floor(temp$total/MAX_ROWS))

    # Go through the page
    get_data <- function(i) {

        temp <- fromJSON(paste0("http://annotator-store.marder.io/",
                                "search?limit=200&offset=", i*MAX_ROWS))

        temp_df <- temp$rows

        # Delete these rows, which are lists, to allow rbind to work.
        # Alternative would be to convert to text, then parse back in
        # PostgreSQL. temp_df$ranges <- NULL
        temp_df$user <- NULL
        temp_df$consumer <- NULL
        temp_df$permissions <- NULL
        temp_df
    }

    df_list <- mclapply(1:i_max, get_data, mc.cores=6)
    df <- do.call("rbind", df_list)
    return(df)
}

# Code to get and clean data ----
system.time(bio_data_raw <- get_es_data())
bio_data <- bio_data_raw
library(parallel)

bio_data$director <- bio_data$text
bio_data$text <- NULL

bio_data$ranges <- unlist(mclapply(bio_data$ranges, toJSON, mc.cores=12))

bio_data$updated <- as.POSIXct(strptime(bio_data$updated, "%Y-%m-%dT%H:%M:%OS"))
bio_data$created <- as.POSIXct(strptime(bio_data$created, "%Y-%m-%dT%H:%M:%OS"))
bio_data$category <- gsub("http://[^/]+//?(\\w+)/.*$", "\\1", bio_data$uri)

# What is this step doing?
bio_data <- subset(bio_data, category!="bio")
bio_data$category[bio_data$category=="highlight"] <- "bio"
bio_data$file_name <-
    gsub("http://[^/]+//?\\w+/(\\d+)/(\\d{10})(\\d{2})(\\d{6}).*$",
         "edgar/data/\\1/\\2-\\3-\\4.txt", bio_data$uri)

# Push data to PostgreSQL ----
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("director_bio", "raw_tagging_data"), bio_data,
             overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "
    ALTER TABLE director_bio.raw_tagging_data
        ALTER COLUMN ranges TYPE jsonb USING ranges::jsonb->0;")

rs <- dbGetQuery(pg, "
    CREATE INDEX ON director_bio.raw_tagging_data (file_name);")

sql <- "ALTER TABLE director_bio.raw_tagging_data OWNER TO director_bio_team;"
rs <- dbGetQuery(pg, sql)
rs <- dbDisconnect(pg)
