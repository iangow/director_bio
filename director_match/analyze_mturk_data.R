library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

mturk_data <- dbGetQuery(pg,"
    WITH

    raw_data AS (
        SELECT worker1 AS worker, worker2 AS other_worker, agreement
        FROM director_bio.mturk_data
        UNION ALL
        SELECT worker2 AS worker, worker1 AS other_worker, agreement
        FROM director_bio.mturk_data),
        
    agree_stats AS(
        SELECT worker, 
            sum(agreement::integer)::float8/count(agreement) AS percent_agree,
            count(agreement) AS number_coded
        FROM raw_data
        GROUP BY worker),
    
    filtered_data AS (
        SELECT a.worker, agreement
        FROM raw_data AS a
        INNER JOIN agree_stats AS b
        ON a.other_worker=b.worker
        WHERE b.percent_agree > 0.0)
    
    SELECT worker, 
        sum(agreement::integer)::float8/count(agreement) AS percent_agree,
        count(agreement) AS number_coded
    FROM filtered_data
    GROUP BY worker")

dbDisconnect(pg)

library(ggplot2)
qplot(number_coded, percent_agree, data=mturk_data)