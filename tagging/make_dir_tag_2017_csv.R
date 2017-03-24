suppressPackageStartupMessages(library(dplyr))
Sys.setenv(PGHOST = "iangow.me", PGDATABASE = "crsp")
pg <- src_postgres()

library(RPostgreSQL)

dbGetQuery(pg$con, "SET work_mem = '2GB'")

bio_data <-
    tbl(pg, sql("SELECT * FROM director_bio.bio_data"))

raw_tagging_data <-
    tbl(pg, sql("SELECT * FROM director_bio.raw_tagging_data"))

other_directorships <-
    tbl(pg, sql("SELECT * FROM director_bio.other_directorships"))


director <-  tbl(pg, sql("SELECT * FROM director_old.director"))

directorship_results <-
    tbl(pg, sql("SELECT * FROM director_bio.directorship_results"))

regex_results <-
    tbl(pg, sql("SELECT * FROM director_bio.regex_results"))

dir_detected <-
    directorship_results %>%
    group_by(director_id, fy_end) %>%
    summarize(dir_detected = bool_or(!non_match)) %>%
    filter(dir_detected)

current_other_dirs <-
    directorship_results %>%
    filter(!future, non_match) %>%
    inner_join(dir_detected) %>%
    compute()

file_lookup <-
    bio_data %>%
    select(director_id, fy_end, file_name) %>%
    compute()

tagged_directorships <-
    raw_tagging_data %>%
    filter(category == "directorships") %>%
    select(uri) %>%
    distinct() %>%
    compute()

dir_lookup <-
    director %>%
    select(director_id, fy_end) %>%
    distinct() %>%
    mutate(director_id_original = director_id,
           director_id = sql("(director_old.equilar_id(director_id),
                  director_old.director_id(director_id))::equilar_director_id")) %>%
    compute()

selected_uris <-
    current_other_dirs %>%
    inner_join(file_lookup) %>%
    inner_join(dir_lookup) %>%
    select(director_id, fy_end, other_directorships,
           director_id_original, file_name) %>%
    mutate(partial_url = regexp_replace(file_name, "edgar/data", "")) %>%
    mutate(partial_url = concat("http://hal.marder.io/directorships", partial_url)) %>%
    mutate(partial_url = regexp_replace(partial_url, "([0-9]{10})-([0-9]{2})-([0-9]{6})\\.txt", "\\1\\2\\3")) %>%
    mutate(uri = concat(partial_url, "/", director_id_original)) %>%
    select(-file_name, -partial_url) %>%
    anti_join(tagged_directorships) %>%
    mutate(rand = random()) %>%
    group_by(other_directorships) %>%
    # filter(rand == min(rand)) %>%
    select(director_id, other_directorships, uri) %>%
    ungroup() %>%
    compute()

tag_directorships <-
    directorship_results %>%
    filter(!future, !past, non_match) %>%
    select(other_directorships, non_match) %>%
    group_by(other_directorships) %>%
    summarize(num_non_matches = sum(as.integer(non_match)),
              num_obs = n()) %>%
    mutate(prop_non_matches = 1 * num_non_matches / num_obs) %>%
    arrange(desc(num_non_matches)) %>%
    ungroup() %>%
    mutate(row_num = row_number()) %>%
    compute() %>%
    top_n(800, wt = -row_num) %>%
    compute()

tag_list <-
    selected_uris %>%
    inner_join(tag_directorships)  %>%
    arrange(desc(num_non_matches)) %>%
    select(other_directorships, num_non_matches, uri) %>%
    collect()

tag_list %>%
    write_csv("~/Google Drive/director_bio/data/tag_dirs_2017.csv")

tag_list %>% count()

# Plot data on directorships
library(ggplot2)

tag_dir_pop <-
    raw_tagging_data %>%
    filter(category == "directorships") %>%
    select(uri, updated, username) %>%
    distinct() %>%
    compute()

tag_dir_pop %>%
    mutate(updated = sql("updated::date")) %>%
    collect() %>%
    ggplot(aes(x=updated, fill=username)) +
    geom_histogram(binwidth = 1) +
    scale_x_date()
