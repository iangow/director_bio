WITH  
tagging_issues AS (
    SELECT *
    FROM director_bio.tagging_issues
    WHERE 'missing_bios' = ANY(issue_category_alt)),
    
equilar_directors AS (
    SELECT DISTINCT director.equilar_id(director_id), 
        director.director_id(director_id), 
        director, fy_end, term_end_date, start_date
    FROM director.director),

equilar_join AS (
    SELECT DISTINCT a.*, file_name, date_filed
    FROM equilar_directors AS a
    INNER JOIN director.equilar_proxies AS b
    USING (equilar_id, fy_end))

SELECT a.*, c.issue, c.url
FROM equilar_join AS A
LEFT JOIN director_bio.tagging_data AS b
USING (file_name, director)
INNER JOIN tagging_issues AS c
USING (file_name)
WHERE quote IS NULL
ORDER BY equilar_id, fy_end, director_id;
