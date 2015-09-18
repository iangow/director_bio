# Push data to PostgreSQL ----
library(dplyr)
pg <- src_postgres()

sql <- "SELECT DISTINCT username, uri, updated -- , category
        FROM director_bio.tagging_data
        WHERE category='bio' AND updated >= '2015-08-24'"

bio_data <- tbl(pg, sql(sql))

bio_data <- as.data.frame(bio_data)
head(bio_data)

# Look at statistics on filings ----
bio_data$username <- gsub("^(.*?)@(.*)$", "\\1",
                          bio_data$username,
                          perl=TRUE)
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
    filter(time_taken<600) %>%
    ggplot(aes(x=time_taken, fill=username)) +
        geom_histogram( binwidth=20) +
        ggtitle("Elapsed time for each filing")
dev.off()
