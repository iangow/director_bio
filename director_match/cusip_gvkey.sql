-- SET work_mem='2GB';

WITH 

-- I scraped 13D and 13F filings for CUSIP-CIK matches.
-- There are occasional errors, so I require at least 10 filings
-- before considering the match useful.
cusip_ciks AS (
    SELECT substr(trim(cusip), 1, 8) AS cusip, cik
    FROM filings.cusip_cik
    WHERE cusip IS NOT NULL
    GROUP BY 1, 2
    HAVING count(*) > 10),

-- This is data from WRDS.
gvkey_cik AS (
    SELECT gvkey, cik::integer
    FROM ciq.wrds_gvkey
    INNER JOIN ciq.wrds_cik
    USING (companyid)),

-- Create a match table
match_table AS (
    SELECT cusip, cik, gvkey
    FROM cusip_ciks
    LEFT JOIN gvkey_cik
    USING (cik))

-- Add the CIK and CUSIPs to the directorship data
SELECT a.*, b.cik, b.gvkey
FROM director_bio.directorship_results AS a
LEFT JOIN match_table AS b
ON a.other_cusip=b.cusip;
