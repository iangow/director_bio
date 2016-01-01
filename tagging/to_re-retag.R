library(dplyr)

pg <- src_postgres()

pablo_tagging <- tbl(pg, sql("
    WITH raw_data AS (
        SELECT uri AS url, regexp_replace(quote, '[\\n|\\s]{2,}', ' ') AS quote
        FROM director_bio.raw_tagging_data
        WHERE created > '2015-12-01' AND category='bio'
            AND username='ptorroella@gmail.com'
        ORDER BY updated)
    SELECT url, string_agg(quote, ' ') AS quotes
    FROM raw_data
    GROUP BY url"))

clean_text <- function(text) {
    temp <- trimws(text)
    temp <- gsub("\n", " ", temp)
    gsub("\\s{2,}", " ", temp, perl=TRUE)
}

library(googlesheets)

# Get the first test sample ----
# You might need to run the next line first (remove # to do so).
# gs_auth()
# gs <- gs_key("1LeYyCOjK0gq8NVLiGumqyzbCBXAnaiM3nAXmgcoc84Y")

# Get the second test sample
gs <- gs_key("1PIEYkDnH7cgdelzcLipdw8H9p7Z5dbeg521POfLFhLw")

library(readr)

pablo_tagging %>%
    collect() %>%
    mutate(quotes=clean_text(quotes)) %>%
    inner_join(gs_read(gs, ws="to_retag")) %>%
    write_csv(path = "~/Google Drive/director_bio/to_reretag.csv")
