DROP TABLE IF EXISTS director_bio.sec_invest;

CREATE TABLE director_bio.sec_invest AS
WITH equilar AS(
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
    LEFT JOIN director_bio.permno_ciks
    USING (permno)),

-- Get restatments involving SEC investigations from Audit Analytics
restatements AS (
    SELECT company_fkey::integer AS cik, file_date, 
        res_begin_date, res_end_date
    FROM audit.feed09filing
    WHERE res_sec_invest)

-- Merge with Equilar using CIKs and
-- year on Equilar that precedes the filing of the restatement
SELECT cik, file_date, equilar_id, max(fy_end) AS fy_end
FROM restatements AS a
LEFT JOIN equilar_w_ciks AS b
ON a.cik=any(b.ciks) AND b.fy_end <= a.file_date
GROUP BY cik, file_date, equilar_id;
