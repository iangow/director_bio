library(dplyr)
pg <- src_postgres()

# Use CRSP to match tickers and CUSIPs to permcos ----
non_matches <- tbl(pg, sql("
    WITH

    director AS (
        SELECT DISTINCT director_id AS director_id_original,
            (director.equilar_id(director_id),
            director.director_id(director_id))::equilar_director_id AS director_id, fy_end
        FROM director.director),

    frequent_non_matches AS (
       SELECT
            (other_director_id::equilar_director_id).equilar_id AS other_equilar_id,
            sum(non_match::integer) AS num_non_matches,
            sum(non_match::integer)/count(non_match)::float8 AS prop_non_matches,
            array_agg(DISTINCT other_directorships[1]) AS other_directorship_names
        FROM director_bio.directorship_results
        WHERE other_start_date < date_filed
            AND (date_filed < other_end_date OR other_end_date IS NULL)
            AND other_public_co
        GROUP BY 1
        ORDER BY 3 DESC
        LIMIT 1000),

    bio_data AS (
        SELECT director_id, fy_end, file_name
        FROM director_bio.bio_data),

    results AS (
        SELECT director_id, fy_end, other_director_id, other_equilar_id, non_match,
            other_directorships, other_public_co, other_start_date, date_filed,
            other_end_date
        FROM director_bio.directorship_results
        WHERE non_match
            AND other_public_co
            AND other_start_date < date_filed
            AND (other_end_date > date_filed OR other_end_date IS NULL)
            AND (director_id, other_director_id) NOT IN
                (SELECT director_id, other_director_id
                FROM director_bio.ra_checked))

    SELECT DISTINCT *
    FROM results
    INNER JOIN frequent_non_matches
    USING (other_equilar_id)
    INNER JOIN bio_data
    USING (director_id, fy_end)
    INNER JOIN director
    USING (director_id, fy_end)
    ORDER BY other_equilar_id, director_id, fy_end")) %>%
    collect()

get_directorship_url <- function(file_name, director_id) {
    url <- gsub('^edgar/data',
                'http://hal.marder.io/directorships', file_name)
    url <- gsub('(\\d{10})-(\\d{2})-(\\d{6})\\.txt',
                '\\1\\2\\3', url)
    return(paste(url, director_id, sep="/"))
}

non_matches$url <- unlist(mapply(get_directorship_url,
                                 non_matches$file_name,
       non_matches$director_id_original))

library(readr)

non_matches$director_id <- paste0("'", non_matches$director_id)
non_matches$other_director_id <- paste0("'", non_matches$other_director_id)
write_csv(non_matches, path="~/Google Drive/director_bio/non_matches.csv")

# library(googlesheets)
#
# # As a one-time thing per user and machine, you will need to run gs_auth()
# # to authorize googlesheets to access your Google Sheets.
#
# gs <- gs_new()
# gs_ws_new(gs, "non_matches", non_matches)
