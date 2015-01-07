library("RPostgreSQL")
pg <- dbConnect(PostgreSQL(), dbname="crsp")
dbGetQuery(pg, "
    CREATE SCHEMA director_bio;

    CREATE TABLE director_bio.ner (director_id text, fy_end date, ner jsonb)")
