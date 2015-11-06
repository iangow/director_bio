library(dplyr)
pg <- src_postgres()

directorship_results <-
        tbl(pg, sql("SELECT * FROM director_bio.directorship_results"))

# How many observations have BoardEx IDs?
directorship_results %>%
    mutate(boardex_match=!is.na(directorid)) %>%
    group_by(boardex_match) %>%
    summarize(count=n()) %>%
    collect()

# How many observations are affected by the "multiple directorid" issue?
directorship_results %>%
    group_by(directorid_issue) %>%
    summarize(count=n()) %>%
    collect()

# How many observations have multiple PERMNO matches?
directorship_results %>%
    group_by(mult_permnos) %>%
    summarize(count=n()) %>%
    collect()

# What is the distribution of non_match?
directorship_results %>%
    group_by(non_match) %>%
    summarize(count=n()) %>%
    collect()

# Are there dupe rows in terms of (director_id, fy_end, other_director_id)?
directorship_results %>%
    filter(!directorid_issue & !mult_permnos) %>%
    group_by(director_id, fy_end, other_director_id) %>%
    summarize(count=n()) %>%
    filter(count > 1) %>%
    collect()
