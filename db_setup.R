# Connect to my database
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

rs <- dbGetQuery(pg, "
    CREATE SCHEMA IF NOT EXISTS director_bio AUTHORIZATION igow;         
    -- CREATE ROLE  director_bio_team;

    GRANT USAGE ON SCHEMA director_bio TO director_bio_team;
    GRANT CREATE ON SCHEMA director_bio TO director_bio_team;
    GRANT director_bio_team TO awahid;
    GRANT director_bio_team TO gyu;
    GRANT director_bio_team TO igow;
                 
    GRANT SELECT ON targeted.equilar_boardex TO director_bio_team")

rs <- dbDisconnect(pg)