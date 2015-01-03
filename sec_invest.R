temp <- dbGetQuery(pg, "
SET work_mem='3GB';

WITH cusips AS (
    SELECT cusip, cik 
    FROM filings.cusip_cik 
    WHERE char_length(cusip)>=8
    GROUP BY cusip, cik 
    HAVING count(*) > 10),

cusip_agg AS (
    SELECT cik, array_agg(substr(cusip,1,8)) AS cusips
    FROM cusips
    GROUP BY cik),

equilar_ids AS (
    SELECT DISTINCT director.equilar_id(company_id), fy_end, trim(cusip) AS cusip
    FROM director.co_fin),

restatements AS (
    SELECT company_fkey::integer AS cik, file_date, res_begin_date, res_end_date
    FROM audit.feed09filing
    WHERE res_sec_invest),

restatement_w_equilar AS (
    SELECT DISTINCT cik, file_date, res_begin_date, b.cusips, c.equilar_id
    FROM restatements AS a
    LEFT JOIN cusip_agg AS b
    USING (cik)
    LEFT JOIN equilar_ids AS c
    ON c.cusip=any(b.cusips)),

matching_year AS (
    SELECT cik, file_date, equilar_id, max(fy_end) AS fy_end
    FROM restatement_w_equilar
    LEFT JOIN equilar_ids
    USING (equilar_id)
    WHERE fy_end <= file_date
    GROUP BY cik, file_date, equilar_id),

directors AS (
    SELECT cik, file_date, array_agg(director) AS directors
    FROM matching_year AS a
    INNER JOIN director.director AS b
    ON a.equilar_id=director.equilar_id(b.director_id) AND a.fy_end=b.fy_end
    GROUP BY cik, file_date)

SELECT *
FROM restatement_w_equilar
LEFT JOIN directors
USING (cik, file_date)")