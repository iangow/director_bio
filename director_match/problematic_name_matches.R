sql <- paste(readLines("director_match/problematic_name_matches.sql"), collapse="\n")

library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())

prob_dirs <- dbGetQuery(pg, sql)

rs <- dbDisconnect(pg)

subset(prob_dirs, num_ages <= 1)

pg <- dbConnect(PostgreSQL())

dbGetQuery(pg, "
    SELECT *
    FROM director.director
    WHERE director.equilar_id(director_id) IN (2557, 2729)
        AND director.director_id(director_id) IN (14054, 14059, 16961, 16968)
    ORDER BY company, fy_end, age")

rs <- dbDisconnect(pg)


