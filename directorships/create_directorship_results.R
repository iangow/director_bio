system("psql -f directorships/create_directorship_results.sql")

library(dplyr)
pg <- src_postgres()

# Use CRSP to match tickers and CUSIPs to permcos ----
results <- tbl(pg, sql("
    SELECT director_id, non_match, unnest(other_directorships) AS other_directorship
    FROM director_bio.directorship_results"))
