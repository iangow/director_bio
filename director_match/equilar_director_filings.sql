SET work_mem='10GB';

WITH directors AS (
    SELECT DISTINCT (director.equilar_id(director_id), director.director_id(director_id))::equilar_director_id AS director_id,
        director, company, fy_end
    FROM director.director),

matches AS (
    SELECT director_id, UNNEST(matched_ids) AS matched_id
    FROM director.director_matches),

matched_directors AS (
    SELECT *
    FROM directors
    INNER JOIN matches
    USING (director_id)),
    
companies AS (
    SELECT director_id, company, fy_end
    FROM directors),
    
director_companies AS (
    SELECT DISTINCT a.director_id, a.fy_end, 
        array_agg(DISTINCT c.company) AS companies
    FROM matched_directors AS a
    INNER JOIN companies AS c
    ON a.matched_id=c.director_id AND a.fy_end > c.fy_end - interval '1 year'
    GROUP BY a.director_id, a.fy_end)

SELECT c.director, c.company, c.fy_end, (a.director_id).*,
    a.companies,
    'http://www.sec.gov/Archives/' || regexp_replace(file_name, 
                   E'(\\d{10})-(\\d{2})-(\\d{6})\\.txt', 
                   E'\\1\\2\\3') AS url
FROM director_companies AS a
INNER JOIN directors AS c
USING (director_id, fy_end)
INNER JOIN director.equilar_proxies AS b
ON (a.director_id).equilar_id=b.equilar_id AND a.fy_end=b.fy_end
ORDER BY equilar_id, director_id, fy_end

