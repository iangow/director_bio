WITH director_ids AS (
    SELECT (director.equilar_id(director_id),
            director.director_id(director_id))::text AS director_id, 
        fy_end, director_id AS director_id_original
    FROM director.director)

SELECT director_id, director_id_original,
    'http://hal.marder.io/directorships/' ||
    regexp_replace(file_name, 
                   E'edgar/data/(\\d+)/(\\d{10})-(\\d{2})-(\\d{6})\\.txt', 
                   E'\\1/\\2\\3\\4') || '/' || director_id_original AS url, *
FROM director_bio.directorship_results
INNER JOIN director_ids
USING (director_id, fy_end)
WHERE non_match
LIMIT 10;

