WITH flagged AS (
    SELECT regexp_replace(url, 
        '.*/(\d+)/(\d{10})(\d{2})(\d{6}).*',
        'edgar/data/\1/\2-\3-\4.txt') AS file_name, 
        COALESCE(issue_category IS NOT NULL, FALSE) AS flagged, *
    FROM director_bio.tagging_issues
    WHERE issue_category ~ 'strikethrough')
SELECT a.quote AS bio, a.director, a.uri
FROM director_bio.bio_data AS a
INNER JOIN flagged AS b
USING (file_name);
