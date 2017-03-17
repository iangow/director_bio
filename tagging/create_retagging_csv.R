library(dplyr)
library(RPostgreSQL)
pg <- src_postgres()

rs <- dbGetQuery(pg$con, "SET work_mem='1GB'")

raw_tagging_data <-
    tbl(pg, sql("SELECT * FROM director_bio.raw_tagging_data"))

test_sample <-
    tbl(pg, sql("SELECT * FROM director_bio.test_sample"))

bio_data <-
    tbl(pg, sql("SELECT * FROM director_bio.bio_data"))

regex_results <-
    tbl(pg, sql("SELECT * FROM director_bio.regex_results"))

directorship_results <-
    tbl(pg, sql("SELECT * FROM director_bio.directorship_results"))

library(readr)

raw_tagging_data %>%
    filter(category == 'bio') %>%
    filter(username ~'^(mmei|gyu)') %>%
    inner_join(bio_data) %>%
    inner_join(
        directorship_results %>%
            filter(!past, !future, non_match) %>%
            select(director_id, fy_end, other_directorships),
        by=c("director_id", "fy_end") ) %>%
    mutate(other_directorship = unnest(other_directorships)) %>%
    select(director, uri, other_directorship) %>%
    group_by(uri) %>%
    summarize(directors = sql("array_agg(DISTINCT director)"),
              other_directorships =sql("array_agg(DISTINCT other_directorship)")) %>%
    collect() %>%
    write_csv("~/Google Drive/director_bio/data/mmei.csv")

directorship_results <-
    tbl(pg, sql("SELECT * FROM director_bio.directorship_results"))
