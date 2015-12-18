
# Get a sample of observations to look at ----
library(dplyr)
pg <- src_postgres()

sql <- sql("
    SELECT a.director_id, a.fy_end, companies[1] AS company,
        other_director_id, director, file_name,
        other_directorships, other_start_date, other_end_date,
        directorid
    FROM director_bio.bio_data AS a
    INNER JOIN director_bio.other_directorships AS b
    USING (director_id, fy_end)
    INNER JOIN director_bio.regex_results AS d
    USING (file_name, director_id, other_director_id)
    WHERE non_match
        AND date_filed > other_start_date  -- exclude future directorships
        AND (other_first_date <= other_start_date -- always public only
            AND other_last_date >= date_filed)")

tagging_url <- function(file_name) {
    temp <- gsub("^edgar/data/", "http://hal.marder.io/highlight/",
                 file_name)
    gsub("(\\d{10})-(\\d{2})-(\\d{6})\\.txt", "\\1\\2\\3", temp)

}

# We want to exclude observations that we've already looked at.
already_sampled <-
    tbl(pg, sql("SELECT * FROM director_bio.test_data")) %>%
    select(director_id, other_director_id, fy_end)

# Use CRSP to match tickers and CUSIPs to permcos ----
full_sample <- tbl(pg, sql) %>%
    anti_join(already_sampled) %>%
    collect() %>%
    mutate(url = tagging_url(file_name))

# Flag observations RAs are looking at already ----
library(googlesheets)

# You might need to run the next line first (remove # to do so).
# gs_auth()
gs <- gs_key("1PIEYkDnH7cgdelzcLipdw8H9p7Z5dbeg521POfLFhLw")
to_retag <-  gs_read(gs, ws="to_retag") %>%
    select(url) %>%
    mutate(to_retag = TRUE)

gs <- gs_key("1_8uFkS0jYS3j6oKCNlPYAhOnbd4d8gEE1nQ67yjoNGk")
empty_director <-  gs_read(gs, ws="empty_director") %>%
    select(url) %>%
    mutate(empty_director = TRUE)

# Take a random sample and save to Google Sheets ----
sample <- full_sample %>%
    left_join(to_retag) %>%
    left_join(empty_director) %>%
    sample_n(50)

sample$director_id <- paste0("'", sample$director_id)
sample$other_director_id <- paste0("'", sample$other_director_id)

sample %>%
    with(table(to_retag, empty_director, useNA="ifany"))

library(readr)
write_csv(sample, path = "~/Google Drive/director_bio/test_sample_2.csv")
