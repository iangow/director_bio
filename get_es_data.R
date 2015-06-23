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

        temp <- fromJSON(paste0("http://annotator-store.marder.io/search?limit=200&offset=", i*200))

        if (length(temp$rows)==0) {
            break
        } else {
            temp_df <- temp$rows

            # Delete these rows, which are lists, to allow rbind to work.
            # Alternative would be to convert to text, then parse back in PostgreSQL.
            temp_df$ranges <- NULL
            temp_df$permissions <- NULL
            df <- rbind(df, temp_df)
        }
        i <- i + 1L
    }

    return(df)
}

bio_data <- get_es_data()
bio_data$updated <- as.POSIXct(strptime(bio_data$updated, "%Y-%m-%dT%H:%M:%OS"))

# Look at statistics on filings so far
table(bio_data$username)
library(dplyr)
bio_data %>%
   group_by(username) %>%
   summarise(num_filings = n_distinct(uri))

pdf(file="figures/productivity.pdf", paper = "USr")
bio_data %>%
    group_by(username, uri) %>%
    summarise(start_time = min(updated), end_time = max(updated)) %>%
    filter(username=="LaurelMcMechan@gmail.com") %>%
    ggplot(aes(x=end_time)) + 
        geom_histogram(binwidth = 60*60) + 
        ggtitle("Filings per hour")

bio_data %>%
    group_by(username, uri) %>%
    summarise(start_time = min(updated), end_time = max(updated), time_taken=end_time-start_time) %>%
    filter(username=="LaurelMcMechan@gmail.com") %>%
    ggplot(aes(x=time_taken)) +
        geom_histogram( binwidth=20) +
        ggtitle("Elapsed time for each filing")
dev.off()
    
        
