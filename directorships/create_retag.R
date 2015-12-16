library(dplyr)
library(tidyr)

pg <- src_postgres()

regex_results <- tbl(pg, sql("SELECT * FROM director_bio.regex_results"))

other_dirs <-
    tbl(pg, sql("SELECT * FROM director_bio.other_directorships")) %>%
    select(director_id, other_director_id, fy_end, other_start_date,
           other_end_date, other_first_date, other_last_date,
           other_directorships) %>%
    filter(other_start_date < fy_end, other_first_date < other_end_date,
           other_last_date > other_start_date)

tagging_url <- function(file_name) {
    temp <- gsub("^edgar/data/", "http://hal.marder.io/highlight/",
                 file_name)
    gsub("(\\d{10})-(\\d{2})-(\\d{6})\\.txt", "\\1\\2\\3", temp)

}

who_tagged <- tbl(pg, sql("
    SELECT file_name, array_agg(DISTINCT username) AS tagged_by
    FROM director_bio.raw_tagging_data
    WHERE category='bio'
    GROUP BY file_name"))

missing_dirs <- tbl(pg, sql("
    WITH missing_dirs AS (
        SELECT DISTINCT file_name, unnest(other_directorships) AS other_directorship
        FROM director_bio.other_directorships
        INNER JOIN director_bio.regex_results
        USING (director_id, other_director_id, fy_end)
        WHERE non_match
            AND other_start_date < fy_end
            AND other_first_date < other_end_date
            AND other_last_date > other_start_date)
    SELECT file_name, array_agg(DISTINCT other_directorship) AS other_directorships
    FROM missing_dirs
    GROUP BY file_name"))

to_retag <-
    regex_results %>%
    semi_join(other_dirs) %>%
    group_by(file_name, non_match) %>%
    summarize(count = n()) %>%
    inner_join(who_tagged) %>%
    inner_join(missing_dirs) %>%
    collect() %>%
    mutate(non_match = tolower(substr(non_match,1,1))) %>%
    spread(non_match, count, fill = 0) %>%
    rename(non_match = t, match = f) %>%
    mutate(total = non_match + match, prop = non_match/total) %>%
    filter(total > 5, prop > 0.75) %>%
    mutate(url = tagging_url(file_name))

library(readr)
write_csv(to_retag, path = "~/Google Drive/director_bio/to_retag.csv")
