SELECT file_name, uri, analyst, username, director, 
    quote AS bio
FROM director_bio.tagging_issues
LEFT JOIN director_bio.tagging_data
USING (file_name)
WHERE 'bios_wrong_place' = ANY(issue_category_alt)
    AND category = 'bio';
