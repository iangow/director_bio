
# Get a sample of observations to look at ----
suppressPackageStartupMessages(library(dplyr))
pg <- src_postgres()

# We want to exclude observations that we've already looked at.
test_sample <-
    tbl(pg, sql("SELECT * FROM director_bio.test_sample"))

other_directorships <-
    tbl(pg, sql("SELECT * FROM director_bio.other_directorships"))

bio_data <-
    tbl(pg, sql("SELECT * FROM director_bio.bio_data"))

regex_results <-
    tbl(pg, sql("SELECT * FROM director_bio.regex_results"))

tagging_url <- function(file_name) {
    temp <- gsub("^edgar/data/", "http://hal.marder.io/highlight/",
                 file_name)
    gsub("(\\d{10})-(\\d{2})-(\\d{6})\\.txt", "\\1\\2\\3", temp)
}

sample <-
    other_directorships %>%
    filter(date_filed > other_start_date) %>%     # exclude future directorships
    filter(other_first_date <= other_start_date,  # always public only
           other_last_date >= date_filed) %>%   # inner_join(bio_data) %>%
    inner_join(
        bio_data %>%
            select(director_id, fy_end, director) %>%
            distinct) %>%
    inner_join(regex_results) %>%
    filter(non_match) %>%
    select(director_id, fy_end, cik, other_director_id, director,
           file_name, other_directorships, other_start_date, other_end_date,
           other_cik, directorid) %>%
    anti_join(test_sample) %>%
    mutate(rand = random()) %>%
    arrange(rand) %>%
    collect(n=50) %>%
    select(-rand) %>%
    mutate(url = tagging_url(file_name))

library(readr)
sample %>%
    mutate(director_id = paste0("'", director_id)) %>%
    mutate(other_director_id = paste0("'", other_director_id)) %>%
    write_csv(path = "~/Google Drive/director_bio/test_sample.csv")
