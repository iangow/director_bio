SET work_mem='10GB';

WITH 

directors AS (
    SELECT DISTINCT director.equilar_id(director_id), 
        director.director_id(director_id), 
        (director.parse_name(director)).*, director, company, fy_end, age, gender
    FROM director.director),

filings AS (
    SELECT DISTINCT equilar_id, fy_end, file_name
    FROM director.equilar_proxies
    WHERE file_name IS NOT NULL)
    
SELECT equilar_id, director, file_name, 
    count(DISTINCT age) AS num_ages,
    count(DISTINCT director_id) AS num_director_ids,
    array_agg(DISTINCT director_id)::text AS director_ids,
    count(DISTINCT director_id) AS num_directors
FROM directors
INNER JOIN filings
USING (equilar_id, fy_end)
GROUP BY equilar_id, director, file_name
HAVING count(DISTINCT director_id) > 1;
