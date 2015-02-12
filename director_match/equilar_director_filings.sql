WITH directors AS (
    SELECT director.equilar_id(director_id) AS equilar_id, fy_end, director
    FROM director.director)
SELECT *,
    regexp_replace(file_name, 
                   E'(\\d{10})-(\\d{2})-(\\d{6})\\.txt', 
                   E'\\1\\2\\3') AS url
FROM directors 
INNER JOIN director.equilar_proxies
USING (equilar_id, fy_end)
