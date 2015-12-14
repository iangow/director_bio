library(googlesheets)
library(dplyr)

# You might need to run the next line first (remove # to do so).
# gs_auth()
gs <- gs_key("1LeYyCOjK0gq8NVLiGumqyzbCBXAnaiM3nAXmgcoc84Y")

test_data <-  gs_read(gs, ws="test_1") %>%
    select(director_id, other_director_id, fy_end, date_filed,
           other_dir_disclosed, as_disclosed, comment, filing_link,
           proposed_resolution)

test_data$fy_end <- as.Date(test_data$fy_end)
test_data$date_filed <- as.Date(test_data$date_filed)
library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("director_bio", "test_data"), test_data %>% as.data.frame(),
                   overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "
    ALTER TABLE director_bio.test_data
    ALTER COLUMN director_id TYPE equilar_director_id
        USING director_id::equilar_director_id;

    ALTER TABLE director_bio.test_data
    ALTER COLUMN other_director_id TYPE equilar_director_id
        USING other_director_id::equilar_director_id;

    ALTER TABLE director_bio.test_data OWNER TO director_bio_team;

    CREATE INDEX ON director_bio.test_data (director_id, other_director_id);")

rs <- dbDisconnect(pg)
rm(pg)

pg <- src_postgres()
merged_test <-
    tbl(pg, sql("
        SELECT *
        FROM director_bio.test_data
        INNER JOIN director_bio.regex_results
        USING (director_id, other_director_id, fy_end)"))

library(readr)
merged_test %>%
    as.data.frame() %>%
    mutate(director_id=paste0("'", director_id),
           other_director_id=paste0("'", other_director_id)) %>%
    write_csv(path="~/Google Drive/director_bio/test_sample.csv")

rs <- dbGetQuery(pg$con, "SET work_mem='1GB'")

who_tagged_sql <- sql("
    WITH who_tagged AS (
        SELECT director, file_name, array_agg(DISTINCT username) AS tagged_by
        FROM director_bio.raw_tagging_data
        WHERE category='bio'
        GROUP BY director, file_name)
    SELECT a.proposed_resolution, c.tagged_by
    FROM director_bio.test_data AS a
    INNER JOIN director_bio.bio_data
    USING (director_id, fy_end)
    INNER JOIN who_tagged AS c
    USING (director, file_name)")

who_tagged <-
    tbl(pg, who_tagged_sql)

who_tagged %>%
    collect() %>%
    with(table(tagged_by, proposed_resolution))

library(readr)
