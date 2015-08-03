WITH 

dupe_bios AS (
    SELECT file_name, director, username,
        array_agg(DISTINCT director_id) AS director_ids
    FROM director_bio.bio_data
    GROUP BY file_name, director, username
    HAVING count(DISTINCT director_id) > 1),
    
flagged_issues AS (
    SELECT regexp_replace(url, 
    '.*/(\d+)/(\d{10})(\d{2})(\d{6}).*',
    'edgar/data/\1/\2-\3-\4.txt') AS file_name, 
        issue_category, analyst, url
    FROM director_bio.tagging_issues)

SELECT *, issue_category IS NOT NULL AS flagged
FROM dupe_bios
LEFT JOIN flagged_issues
USING (file_name);
