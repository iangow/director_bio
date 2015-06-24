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
bio_data$username <- gsub("^(.*?)@(.*)$", "\\1",
                          bio_data$username,
                          perl=TRUE)

# Look at statistics on filings ----
table(bio_data$username)
library(dplyr)
bio_data %>%
   group_by(username) %>%
   summarise(num_filings = n_distinct(uri))

# Produce some plots ----
if (!dir.exists("figures")) dir.create("figures")
pdf(file="figures/productivity.pdf", paper = "USr", width=9)

library(ggplot2)
library(scales) 
bio_data %>%
    group_by(username, uri) %>%
    summarise(start_time = min(updated), end_time = max(updated), 
              time_taken=end_time-start_time) -> 
    plot_data

plot_data %>% 
    ggplot(aes(x=end_time, fill=username)) + 
        geom_histogram(binwidth=60*60) + 
        scale_x_datetime(name="Time (hour)", 
                         breaks=("2 hour"), minor_breaks=("1 hour"),
                          labels=date_format("%H")) +
        ggtitle("Filings per hour") 
       

plot_data %>%
    ggplot(aes(x=time_taken, fill=username)) +
        geom_histogram( binwidth=20) +
        ggtitle("Elapsed time for each filing")
dev.off()
    
        
