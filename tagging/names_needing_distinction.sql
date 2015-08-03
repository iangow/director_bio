SET work_mem='1GB';

WITH 

director_bios AS (
    SELECT DISTINCT file_name, director, username,
        quote AS bio
    FROM director_bio.bio_data),

dupe_bios AS (
    SELECT file_name, director, username, uri,
        array_agg(DISTINCT director_id) AS director_ids
    FROM director_bio.bio_data
    GROUP BY file_name, director, username
    HAVING count(DISTINCT director_id) > 1),
    
flagged_issues AS (
    SELECT DISTINCT regexp_replace(url, 
    '.*/(\d+)/(\d{10})(\d{2})(\d{6}).*',
    'edgar/data/\1/\2-\3-\4.txt') AS file_name, analyst
    FROM director_bio.tagging_issues)

SELECT file_name, director, username,
    UNNEST(director_ids) AS director_id,
    analyst IS NOT NULL AS flagged, b.analyst,
    a.uri, c.bio
FROM dupe_bios AS a
LEFT JOIN flagged_issues AS b
USING (file_name)
INNER JOIN director_bios AS c
USING (file_name, director, username)
ORDER BY file_name, director, director_id;
