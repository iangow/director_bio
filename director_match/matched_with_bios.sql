WITH raw_matches AS (
    SELECT DISTINCT director_id, unnest(matched_ids) AS matched_id
    FROM director.director_matches
    WHERE array_length(matched_ids, 1) > 2),

matches AS (
    SELECT *
    FROM raw_matches
    WHERE director_id != matched_id),

latest_bio_years AS (
    SELECT director_id, max(fy_end) AS fy_end
    FROM director_bio.bio_data
    GROUP BY director_id),

latest_bios AS (
    SELECT director_id, bio, company_name, fy_end
    FROM director_bio.bio_data
    INNER JOIN filings.filings
    USING (file_name)
    INNER JOIN latest_bio_years
    USING (director_id, fy_end))

SELECT a.director_id::text, a.matched_id::text, b.fy_end, c.fy_end AS matched_fy_end,
    b.company_name, c.company_name AS matched_company_name,
    -- Need to add company names. I guess ideally from the proxy filing from which the bio came.
    b.bio, c.bio AS matched_bio
FROM matches AS a
LEFT JOIN latest_bios AS b
ON a.director_id=b.director_id
LEFT JOIN latest_bios AS c
ON a.matched_id=c.director_id;
