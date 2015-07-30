# Code to get and analyze data from ElasticSearch store.
# 
get_es_data <- function() {
# Function to get data from ElasticSearch
# I'm not sure how robust this is. Probably best to only run this when the data are not changing.
# Not clear how robust this is in get each record only once and getting all records.

    library(jsonlite)
    library(curl)

    df <- data.frame()
    i <- 0L

    # Go through the page
    while (TRUE) {

        temp <- fromJSON(paste0("http://annotator-store.marder.io/", 
                                "search?limit=200&offset=", i*200))

        if (length(temp$rows)==0) {
            break
        } else {
            temp_df <- temp$rows

            # Delete these rows, which are lists, to allow rbind to work.
            # Alternative would be to convert to text, then parse back in PostgreSQL.
            # temp_df$ranges <- NULL
            temp_df$user <- NULL
            temp_df$consumer <- NULL
            temp_df$permissions <- NULL
            df <- rbind(df, temp_df)
        }
        i <- i + 1L
    }

    return(df)
}

bio_data <- get_es_data()
library(parallel)

bio_data$director <- bio_data$text
bio_data$text <- NULL

bio_data$ranges <- unlist(mclapply(bio_data$ranges, toJSON, mc.cores=12))

bio_data$updated <- as.POSIXct(strptime(bio_data$updated, "%Y-%m-%dT%H:%M:%OS"))
bio_data$created <- as.POSIXct(strptime(bio_data$created, "%Y-%m-%dT%H:%M:%OS"))
bio_data$category <- gsub("http://[^/]+//?(\\w+)/.*$", "\\1", bio_data$uri)
bio_data <- subset(bio_data, category!="bio")
bio_data$category[bio_data$category=="highlight"] <- "bio"
bio_data$file_name <- 
    gsub("http://[^/]+//?\\w+/(\\d+)/(\\d{10})(\\d{2})(\\d{6}).*$", 
         "edgar/data/\\1/\\2-\\3-\\4.txt", bio_data$uri)

# save(file="tagging/bio_data.Rdata", bio_data)


# Push data to PostgreSQL ----
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("director_bio", "tagging_data"), bio_data,
             overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "
    ALTER TABLE director_bio.tagging_data
        ALTER COLUMN ranges TYPE jsonb USING ranges::jsonb->0;
           
    CREATE INDEX ON director_bio.tagging_data (file_name);

    DROP TABLE IF EXISTS director_bio.bio_data;

    CREATE TABLE director_bio.bio_data AS
    WITH

    directors AS (
        SELECT director.equilar_id(director_id) AS equilar_id,
            director.director_id(director_id) AS director_id,
            fy_end, director
        FROM director.director),
    
    directors_w_proxies AS (
        SELECT *
        FROM directors 
        INNER JOIN director.equilar_proxies
        USING (equilar_id, fy_end))

    SELECT *
    FROM director_bio.tagging_data AS a
    INNER JOIN directors_w_proxies AS b
    USING (file_name, director)
    WHERE category='bio';
           
    ALTER TABLE director_bio.bio_data
        ALTER COLUMN director_id TYPE equilar_director_id 
            USING (equilar_id, director_id)::equilar_director_id;")

rs <- dbDisconnect(pg)
