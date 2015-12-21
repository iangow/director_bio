
library(googlesheets)
library(dplyr)

# Get the first test sample ----
# You might need to run the next line first (remove # to do so).
# gs_auth()
# gs <- gs_key("1LeYyCOjK0gq8NVLiGumqyzbCBXAnaiM3nAXmgcoc84Y")

# Get the second test sample
gs <- gs_key("16lq6rFmBUDoALvzAItTxcytVMEDv4yqOGmLFkoJrOqE")

get_test_sample <- function(sheet_num) {
    ws <- paste0("test_sample #", sheet_num)
    gs_read(gs, ws=ws) %>%
        select(director_id, other_director_id, fy_end,
           other_dir_undisclosed, as_disclosed, comment,
           proposed_resolution) %>%
        mutate(sheet=ws)
}

# There are 3 worksheets to import and combine
test_sample <- lapply(1:3, get_test_sample) %>%
	do.call("rbind", .)

test_sample$fy_end <- as.Date(test_sample$fy_end)
library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("director_bio", "test_sample"), test_sample %>% as.data.frame(),
                   overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "
    ALTER TABLE director_bio.test_sample
    ALTER COLUMN director_id TYPE equilar_director_id
        USING director_id::equilar_director_id;

    ALTER TABLE director_bio.test_sample
    ALTER COLUMN other_director_id TYPE equilar_director_id
        USING other_director_id::equilar_director_id;

    ALTER TABLE director_bio.test_sample OWNER TO director_bio_team;

    CREATE INDEX ON director_bio.test_sample (director_id, other_director_id);")

rs <- dbDisconnect(pg)
rm(pg)

pg <- src_postgres()
rs <- dbGetQuery(pg$con, "SET work_mem='1GB'")

who_tagged_sql <- sql("
    WITH who_tagged AS (
        SELECT director, file_name, array_agg(DISTINCT username) AS tagged_by
        FROM director_bio.raw_tagging_data
        WHERE category='bio'
        GROUP BY director, file_name)
    SELECT a.proposed_resolution, c.tagged_by
    FROM director_bio.test_sample AS a
    INNER JOIN director_bio.bio_data
    USING (director_id, fy_end)
    INNER JOIN who_tagged AS c
    USING (director, file_name)")

who_tagged <-
    tbl(pg, who_tagged_sql)

who_tagged %>%
    collect() %>%
    with(table(tagged_by, proposed_resolution))

merged_test <-
    tbl(pg, sql("
        SELECT *
        FROM director_bio.test_sample
        INNER JOIN director_bio.regex_results
        USING (director_id, other_director_id, fy_end)")) %>%
    collect()

merged_test %>%
    with(table(proposed_resolution, non_match))

results <-
    merged_test %>%
    filter(non_match, !is.na(other_dir_undisclosed)) %>%
    group_by(other_dir_undisclosed) %>%
    summarize(count=n())

accuracy <- subset(results, other_dir_undisclosed,
                   select=count)/sum(results$count)
sprintf("For a sample of %3.0f non-matches, accuracy is currently %3.2f%%.",
        sum(results$count), accuracy*100)
