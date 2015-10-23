SET work_mem='2GB';

WITH

non_matches AS (
    SELECT (other_director_id::equilar_director_id).equilar_id AS other_equilar_id, 
        sum(non_match::integer) AS num_non_matches,
        sum(non_match::integer)/count(non_match)::float8 AS prop_non_matches,
        array_agg(DISTINCT other_directorship) AS other_directorship_names
    FROM director_bio.directorship_results
    GROUP BY 1
    ORDER BY 2 DESC),

director_ids AS (
    SELECT DISTINCT (director.equilar_id(director_id),
            director.director_id(director_id))::text AS director_id, 
        fy_end, director_id AS director_id_original
    FROM director.director),

other_directorships AS (
    SELECT DISTINCT equilar_id, fy_end, director_id::text, 
        other_director_id::text, 
        (other_director_id).equilar_id AS other_equilar_id
    FROM director_bio.other_directorships),

directorship_results AS (
    SELECT DISTINCT director_id, fy_end, file_name, other_director_id
    FROM director_bio.directorship_results)

SELECT director_id, fy_end, director_id_original,
    'http://hal.marder.io/directorships/' ||
    regexp_replace(file_name, 
                   E'edgar/data/(\\d+)/(\\d{10})-(\\d{2})-(\\d{6})\\.txt', 
                   E'\\1/\\2\\3\\4') || '/' || director_id_original AS url, b.*
FROM directorship_results
INNER JOIN director_ids AS a
USING (director_id, fy_end)
INNER JOIN other_directorships
USING (director_id, fy_end, other_director_id)
INNER JOIN non_matches AS b
USING (other_equilar_id)
ORDER BY num_non_matches DESC
LIMIT 10;

