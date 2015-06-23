SET work_mem='10GB';

WITH 

directors AS (
    SELECT DISTINCT director.equilar_id(director_id), 
          (director.equilar_id(director_id),
           director.director_id(director_id))::equilar_director_id AS director_id,
          (director.parse_name(director)).*, director, company, fy_end, age, gender
    FROM director.director),

filings AS (
    SELECT DISTINCT equilar_id, fy_end, file_name
    FROM director.equilar_proxies
    WHERE file_name IS NOT NULL)
    
SELECT director, file_name, 
    array_agg(age) AS ages,
    array_agg(director_id) AS director_ids,
    count(director_id) AS num_directors
FROM directors
INNER JOIN filings
USING (equilar_id, fy_end)
GROUP BY director, file_name
HAVING count(DISTINCT director_id) > 1;