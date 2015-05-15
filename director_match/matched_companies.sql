WITH directors AS (
     SELECT DISTINCT (director.equilar_id(director_id), director.director_id(director_id))::equilar_director_id AS director_id,
        company, fy_end
    FROM director.director),

matches AS (
    SELECT director_id, UNNEST(matched_ids) AS matched_id
    FROM director.director_matches
    LIMIT 100),

companies AS (
    SELECT director_id, company, fy_end
    FROM directors)
    
SELECT DISTINCT a.director_id, array_agg(c.company) AS companies
FROM directors AS a
INNER JOIN matches AS b
USING (director_id)
INNER JOIN companies AS c
ON b.matched_id=c.director_id AND a.fy_end > c.fy_end - interval '1 year'
GROUP BY a.director_id;
