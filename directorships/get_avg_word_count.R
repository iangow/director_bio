library(dplyr, warn.conflicts = FALSE)
library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())

dbGetQuery(pg, "SET work_mem='10GB'")

bio_data <- tbl(pg, sql("SELECT * FROM director_bio.bio_data"))

bio_word_counts <- bio_data %>%
    mutate(sents = sent_tokenize(bio)) %>%
    mutate(sent = unnest(sents)) %>%
    mutate(words = word_tokenize(sent)) %>%
    group_by(director_id, file_name) %>%
    summarize(word_count = sum(array_length(words, 1L))) %>%
    ungroup() %>%
    compute(name = "bio_word_counts", temporary = FALSE)

bio_word_counts <- tbl(pg, sql("SELECT * FROM bio_word_counts"))

bio_word_counts %>%
    summarize(mean = mean(word_count), median = median(word_count))

library(ggplot2)
bio_word_counts %>%
    select(word_count) %>%
    collect() %>%
    ggplot(x = word_count) +
    geom_histogram()
