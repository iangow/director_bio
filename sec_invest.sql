DROP TABLE IF EXISTS director_bio.sec_invest;

CREATE TABLE director_bio.sec_invest AS

-- Get restatments involving SEC investigations from Audit Analytics
WITH restatements AS (
    SELECT company_fkey::integer AS cik, file_date, 
        res_begin_date, res_end_date
    FROM audit.feed09filing
    WHERE res_sec_invest)

-- Merge with Equilar using CIKs and
-- year on Equilar that precedes the filing of the restatement
SELECT cik, file_date, equilar_id, max(fy_end) AS fy_end
FROM restatements AS a
LEFT JOIN director.ciks AS b
ON a.cik=any(b.ciks) AND b.fy_end <= a.file_date
GROUP BY cik, file_date, equilar_id;
