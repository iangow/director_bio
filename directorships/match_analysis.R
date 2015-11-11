library(dplyr)
pg <- src_postgres()

dir_chars <- tbl(pg, sql("SELECT * FROM boardex.director_characteristics"))

dir_chars %>%
    filter(directorid==106247) %>%
    select(director_name, board_name) %>%
    distinct() %>%
    collect()

results <-
    tbl(pg, sql("SELECT * FROM director_bio.directorship_results")) %>%
    filter(non_match, other_public_co,
           other_start_date < date_filed,
           other_end_date > date_filed | is.na(other_end_date)

director <- tbl(pg, sql("
        SELECT DISTINCT director_id AS director_id_original,
            (director.equilar_id(director_id),
            director.director_id(director_id))::equilar_director_id AS director_id, fy_end
        FROM director.director"))

bio_data <- tbl(pg, sql("
    SELECT director_id, fy_end, file_name
    FROM director_bio.bio_data"))

merged <- results %>%
    inner_join(bio_data) %>%
    inner_join(director) %>%
    collect()

get_directorship_url <- function(file_name, director_id) {
    url <- gsub('^edgar/data', 'http://hal.marder.io/directorships', file_name)
    url <- gsub('(\\d{10})-(\\d{2})-(\\d{6})\\.txt', '\\1\\2\\3', url)
    return(paste(url, director_id, sep="/"))
}

merged$url <- unlist(mapply(get_directorship_url, merged$file_name,
       merged$director_id_original))


library(foreign)
write.dta(merged, "~/Google Drive/director_bio/merged.dta")
temp <- merged %>%
    filter(director_id=="(7340,72644)",
           other_director_id=="(2629,14999)")

temp <- merged %>%
    filter(other_director_id=="(7340,72644)",
           director_id=="(2629,14999)")

stocknames <-
        tbl(pg, sql("SELECT * FROM crsp.stocknames"))

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
