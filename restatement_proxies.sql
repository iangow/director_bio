tWITH equilar AS(
    SELECT trim(cusip) AS cusip,
        director.equilar_id(company_id) AS equilar_id, fy_end
    FROM director.co_fin),
permno_cusip AS (
    SELECT DISTINCT permno, ncusip AS cusip
    FROM crsp.stocknames),
-- CUSIP-CIK matches come from two sources:
--  - Scraping 13/D and 13/G filings and
--  - WRDS's Capital IQ database
cusip_cik AS (
    SELECT substr(cusip, 1, 8) AS cusip, cik
    FROM filings.cusip_cik 
    WHERE char_length(trim(cusip))>=8
    GROUP BY substr(cusip, 1, 8), cik 
    HAVING count(*) > 5
    UNION 
    SELECT DISTINCT substr(cusip, 1, 8) AS cusip, cik::integer
    FROM ciq.wrds_cusip
    INNER JOIN ciq.wrds_cik
    USING (companyid)),
-- Get all CIKs that match each PERMNO, using CUSIPs as the link
permno_ciks AS (
    SELECT permno, array_agg(cik) AS ciks
    FROM permno_cusip
    INNER JOIN cusip_cik
    USING (cusip)
    GROUP BY permno),
-- Add CIKs to Equilar data, going via PERMNOs to CUSIPs
equilar_w_ciks AS (
    SELECT equilar_id, cusip, fy_end, ciks
    FROM equilar AS a
    LEFT JOIN permno_cusip AS b
    USING (cusip)
    LEFT JOIN permno_ciks
    USING (permno)),
-- Get restatments involving SEC investigations from Audit Analytics
restatements AS (
    SELECT company_fkey::integer AS cik, file_date, 
        res_begin_date, res_end_date
    FROM audit.feed09filing
    WHERE res_sec_invest),
-- Merge with Equilar using CIKs
restatement_w_equilar AS (
    SELECT DISTINCT cik, file_date, res_begin_date, equilar_id
    FROM restatements AS a
    LEFT JOIN equilar_w_ciks AS b
    ON a.cik=any(b.ciks)),
-- Find year on Equilar that precedes the filing of the restatement
matching_year AS (
    SELECT cik, file_date, equilar_id, max(fy_end) AS fy_end
    FROM restatement_w_equilar
    LEFT JOIN equilar_w_ciks
    USING (equilar_id)
    WHERE fy_end <= file_date
    GROUP BY cik, file_date, equilar_id),
-- Get names of directors from Equilar
directors AS (
    SELECT cik, file_date, array_agg(director) AS directors
    FROM matching_year AS a
    INNER JOIN director.director AS b
    ON a.equilar_id=director.equilar_id(b.director_id) AND a.fy_end=b.fy_end
    GROUP BY cik, file_date),
-- Merge in director names with merged restatement data
restatement_w_directors AS (
    SELECT *
    FROM restatement_w_equilar
    LEFT JOIN directors
    USING (cik, file_date)),
                   
-- Get all proxy filings on EDGAR
proxy_filings AS (
    SELECT cik::integer, date_filed, file_name
    FROM filings.filings
    WHERE form_type ~ '^DEF 14'),
-- Identify the most recent filing preceding the filing of the restatement
-- Not sure that this is always the one we'd want.
matched_filings AS (
    SELECT cik, file_date, max(date_filed) AS date_filed
    FROM proxy_filings 
    INNER JOIN restatements
    USING (cik)
    WHERE date_filed <= file_date
    GROUP BY cik, file_date)
-- Now merge restatement data with data on proxy filings
SELECT *
FROM restatement_w_directors
LEFT JOIN matched_filings
USING (cik, file_date)
LEFT JOIN proxy_filings
USING (cik, date_filed)

