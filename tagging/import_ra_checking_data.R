library(googlesheets)
library(dplyr)

# You might need to run the next line first (remove # to do so).
# gs_auth()
gs <- gs_key("1L0XqboEEMMkbPH5PBc3rWxDkOMnXCT5EhZ7dsUDFnmM")

get_ra_data <- function(sheet_num) {
    ws <- paste0("non_matches #", sheet_num)
    gs_read(gs, ws=ws) %>%
        mutate(sheet=ws)
}

# There are 7 worksheets to import and combine
ra_checked <- lapply(1:7, get_ra_data) %>%
	do.call("rbind", .)

library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("director_bio", "ra_checked"), ra_checked %>% as.data.frame(),
                   overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "
    ALTER TABLE director_bio.ra_checked
    ALTER COLUMN director_id TYPE equilar_director_id
        USING director_id::equilar_director_id;

    ALTER TABLE director_bio.ra_checked
    ALTER COLUMN other_director_id TYPE equilar_director_id
        USING other_director_id::equilar_director_id;

    ALTER TABLE director_bio.ra_checked OWNER TO director_bio_team;

    CREATE INDEX ON director_bio.ra_checked (director_id, other_director_id);")

 ra_checked %>% filter(grepl("[7]$", sheet)) %>% with(table(Comment, Assignee))
