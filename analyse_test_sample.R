library(dplyr)
library(RPostgreSQL)
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
    filter(non_match) %>%
    with(table(proposed_resolution, other_dir_undisclosed, useNA="ifany"))

merged_test %>%
    filter(non_match) %>% # , !is.na(other_dir_undisclosed)) %>%
    group_by(sheet) %>%
    summarize(count=n(),
              prop_correct=sum(other_dir_undisclosed, na.rm=TRUE)/n())

merged_test %>%
    filter(non_match) %>%
    summarize(count=n(),
              prop_correct=sum(other_dir_undisclosed==non_match,
                               na.rm=TRUE)/n())
