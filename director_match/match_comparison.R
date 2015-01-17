library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

mturk.ages <- dbGetQuery(pg, "
    WITH 
    
    mturk AS (
        SELECT director_id_left::integer[], 
            director_id_right::integer[],
            director_bio_right,
            director_bio_left,
            answer1, answer2
        FROM director_bio.mturk_data),
    
    raw_data AS (
        SELECT ARRAY[director.equilar_id(director_id), director.director_id(director_id)] AS director_id,
            max(age) AS age
        FROM board.director
    	WHERE director_id IS NOT NULL
    	GROUP BY ARRAY[director.equilar_id(director_id), director.director_id(director_id)])
    
    SELECT a.*,
        b.age AS age_left, c.age AS age_right,
        abs(b.age - c.age) AS age_difference
    FROM mturk AS a
    INNER JOIN raw_data AS b
    ON a.director_id_left=b.director_id
    INNER JOIN raw_data AS c
    ON a.director_id_right=c.director_id")

dbDisconnect(pg)