library(dplyr)
pg <- src_postgres()

empty_director <-
    tbl(pg, sql("
        SELECT uri, updated, quote
        FROM director_bio.raw_tagging_data
        WHERE category='bio' AND director=''
        ORDER BY uri, updated"))

library(readr)
write_csv(empty_director %>% collect(),
          path = "~/Google Drive/director_bio/empty_director.csv")
