WITH flagged AS (
    SELECT  
        COALESCE(issue_category IS NOT NULL, FALSE) AS flagged, *
    FROM director_bio.tagging_issues
    WHERE issue_category = 'strikethrough')
SELECT b.file_name, a.quote AS bio, a.director, a.uri, b.url
FROM director_bio.bio_data AS a
RIGHT JOIN flagged AS b
USING (file_name);
