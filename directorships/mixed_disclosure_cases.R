suppressPackageStartupMessages(library(dplyr))

pg <- src_postgres()

RPostgreSQL::dbGetQuery(pg$con, "SET work_mem='2GB'")

directorship_results <-
    tbl(pg, sql("SELECT * FROM director_bio.directorship_results"))

raw_data <-
    directorship_results %>%
    mutate(future = other_start_date > date_filed) %>%
    filter(!future) %>%
    mutate(fiscal_year = fiscal_year(fy_end)) %>%
    select(other_director_id, director_id, fy_end,
           fiscal_year, non_match)

mult_boards <-
    raw_data %>%
    select(other_director_id, fiscal_year, director_id) %>%
    distinct() %>%
    group_by(other_director_id, fiscal_year) %>%
    summarize(num_boards = n()) %>%
    filter(num_boards > 1)

mixed_disc_firm <-
    raw_data %>%
    select(other_director_id, fiscal_year, non_match) %>%
    distinct() %>%
    group_by(other_director_id, fiscal_year) %>%
    summarize(num_discs = n()) %>%
    filter(num_discs > 1)

# Cases of mixed disclosure
mixed_disc_dir <-
    raw_data %>%
    select(other_director_id, fiscal_year, non_match) %>%
    distinct() %>%
    group_by(other_director_id, fiscal_year) %>%
    summarize(num_discs = n()) %>%
    filter(num_discs > 1)

merged <-
    raw_data %>%
    inner_join(mixed_disc_dir)

final <-
    merged %>%
    inner_join(
        directorship_results %>%
            select(other_director_id, director_id, fy_end,
                   directorid, equilar_id)) %>%
    arrange(directorid, fiscal_year) %>%
    compute()

