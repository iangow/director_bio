SET work_mem='1GB';

WITH 

director_data AS (
    SELECT file_name, (director.equilar_id(director_id), 
        director.director_id(director_id))::equilar_director_id AS director_id,
        age, chairman, committees, start_date, term_end_date
    FROM director.director AS a
    INNER JOIN director.equilar_proxies AS b
    ON director.equilar_id(a.director_id) = b.equilar_id AND 
        a.fy_end=b.fy_end),

director_bios AS (
    SELECT DISTINCT file_name, director, username,
        quote AS bio
    FROM director_bio.bio_data),

dupe_bios AS (
    SELECT file_name, director, username, uri,
        array_agg(DISTINCT director_id) AS director_ids
    FROM director_bio.bio_data
    GROUP BY file_name, director, username, uri
    HAVING count(DISTINCT director_id) > 1),
    
flagged_issues AS (
    SELECT DISTINCT regexp_replace(url, 
    '.*/(\d+)/(\d{10})(\d{2})(\d{6}).*',
    'edgar/data/\1/\2-\3-\4.txt') AS file_name, analyst
    FROM director_bio.tagging_issues),

basic_data AS (
    SELECT file_name, director, username,
        UNNEST(director_ids) AS director_id,
        analyst IS NOT NULL AS flagged, b.analyst,
        a.uri, c.bio
    FROM dupe_bios AS a
    LEFT JOIN flagged_issues AS b
    USING (file_name)
    INNER JOIN director_bios AS c
    USING (file_name, director, username))
    
SELECT file_name, director, username, director_id::text,
    flagged, analyst, uri, bio,
    age, chairman, committees, start_date, term_end_date
FROM basic_data
INNER JOIN director_data
USING (file_name, director_id)
ORDER BY file_name, director, director_id;
