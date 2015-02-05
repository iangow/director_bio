SET work_mem='3GB';

-- Get all restatements from Audit Analytics.
WITH restatements AS (
    SELECT company_fkey::integer AS cik, file_date, 
        res_begin_date, res_end_date
    FROM audit.feed09filing
    WHERE res_sec_invest),

-- It seems that directors can have multiple start dates; we want
-- the min of these as date_start_role and the max of these as
-- date_end_role, unless there is a missing value, which seems to 
-- imply that the director is still in that role.
-- Note that I often have year_end_role and year_start_role
-- available when date_start_role or date_end_role aren't.
-- But not always.
boardex_directors AS (
    SELECT companyid AS boardid, directorid, director_name,
        min(date_start_role) AS date_start_role, 
        CASE WHEN bool_or(date_end_role IS NULL) THEN NULL
            ELSE max(date_end_role) END AS date_end_role
    FROM boardex_2014.director_profile_employment
    WHERE brd_position IN ('Yes', 'Outside', 'Inside')
    GROUP BY companyid, directorid, director_name),   

-- Now add CIK and company name from company_profile_details
-- table.
boardex_directors_w_cos AS (
    SELECT boardid, a.cikcode AS cik, a.board_name, 
        b.directorid, b.director_name, 
        b.date_start_role, b.date_end_role
    FROM boardex_2014.company_profile_details AS a
    INNER JOIN boardex_directors AS b
    USING (boardid)
    -- We need valid CIKs to match with Audit Analytics
    WHERE cikcode IS NOT NULL AND cikcode != 0),

-- Identify the directors that were on the board immediately before
-- the restatement was filed.
restatement_directors AS (
    SELECT a.cik AS restate_cik, file_date AS restate_file_date, b.directorid
    FROM restatements AS a
    LEFT JOIN boardex_directors_w_cos AS b
    ON a.cik=b.cik AND a.file_date >= b.date_start_role
        AND (a.file_date <= b.date_end_role OR b.date_end_role IS NULL)),

-- Now get all boards on which those directors sat.
-- Limit to cases where either:
-- (i) director started after restatement was filed
-- (ii) director was still there when restatement was filed
-- (iii) director still there today (IS NULL)
boardex_audit AS (
    SELECT b.restate_cik, b.restate_file_date, a.*
    FROM restatement_directors AS b
    LEFT JOIN boardex_directors AS a
    ON a.directorid=b.directorid 
        AND (restate_file_date <= date_start_role
            OR restate_file_date <= date_end_role 
            OR date_end_role IS NULL))
        
SELECT a.*, c.date_filed, c.file_name
FROM boardex_audit AS a
LEFT JOIN boardex_2014.company_profile_details AS b
USING (boardid)
LEFT JOIN 
    (SELECT * FROM filings.filings WHERE form_type='DEF 14A') AS c
ON b.cikcode=c.cik::integer AND c.date_filed >= a.restate_file_date 
    AND (c.date_filed <= a.date_end_role OR a.date_end_role IS NULL)
ORDER BY restate_cik, restate_file_date, directorid, boardid, date_filed;
