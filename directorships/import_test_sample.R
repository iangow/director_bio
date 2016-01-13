
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

# There are 4 worksheets to import and combine
test_sample <- lapply(1:4, get_test_sample) %>%
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
