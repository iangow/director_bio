SET work_mem='15GB';

DROP TABLE IF EXISTS director_bio.other_directorships;

CREATE TABLE director_bio.other_directorships AS
WITH

-- Currently using the earliest filing date. This should be based on the filing
-- date of the filing we get the bios from.
filing_dates AS (
    SELECT equilar_id, fy_end, min(date_filed) AS date_filed
    FROM director_old.equilar_proxies
    GROUP BY 1, 2),

-- Pull together the list of company names associated with each firm
companies AS (
    SELECT DISTINCT director_old.equilar_id(company_id) AS equilar_id,
        array_agg(DISTINCT company) AS companies
    FROM director_old.co_fin
    GROUP BY 1),

-- Collect GVKEYs & CIKs for each Equilar firm-year
gvkeys AS (
    SELECT DISTINCT equilar_id, fy_end, a.cik, a.gvkey
    FROM director_old.equilar_proxies AS a
    WHERE valid_date AND gvkey IS NOT NULL),

-- Check upstream code for db_merge. I'm only using this for CUSIPs now.
-- Does db_merge add much in this respect?
stockdates AS (
    SELECT equilar_id,
        array_agg(DISTINCT permno) AS permnos,
        min(namedt) AS first_date,
        max(nameenddt) AS last_date
    FROM crsp.stocknames AS a
    INNER JOIN (
        SELECT DISTINCT equilar_id, cusip AS ncusip
        FROM director_old.db_merge) AS b
    USING (ncusip)
    GROUP BY 1),

-- The set of director-firm-year observations.
director AS (
    SELECT (director_old.equilar_id(director_id),
        director_old.director_id(director_id))::equilar_director_id AS director_id,
        director_old.equilar_id(director_id), fy_end
    FROM director_old.director),

-- Extract data on matched director_id values
matched_ids_all AS (
    SELECT director_id, (director_id).equilar_id,
        UNNEST(matched_ids) AS other_director_id,
	    (UNNEST(matched_ids)).equilar_id AS other_equilar_id,
	    directorid
    FROM director_old.director_matches),

-- Drop observations on the same firm (clearly not *other* directorships)
matched_ids AS (
    SELECT *
    FROM matched_ids_all
    WHERE equilar_id!=other_equilar_id),

other_directorships AS (
    SELECT DISTINCT
        a.director_id, a.fy_end, a.equilar_id,

        -- Matched director-level data
        c.directorid,
        c.other_equilar_id,
        c.other_director_id,

        -- Identifiers for the "other" company
        d.companies AS other_directorships

    FROM director AS a
    INNER JOIN matched_ids AS c
    USING (director_id)
    INNER JOIN companies AS d
    ON d.equilar_id=c.other_equilar_id),

-- Add GVKEY and CIKs
other_directorships_w_gvkeys AS (
    SELECT a.*, b.gvkey, b.cik, c.date_filed
    FROM other_directorships AS a
    LEFT JOIN gvkeys AS b
    USING (equilar_id, fy_end)
    INNER JOIN filing_dates AS c
    USING (equilar_id, fy_end)),

term_dates AS (
    SELECT director_id,
        start_date,
        COALESCE(end_date, boardex_term_end_date,
                 implied_end_date, last_fy_end) AS end_date,
        CASE
            WHEN end_date IS NOT NULL THEN 'Equilar'
            WHEN boardex_term_end_date IS NOT NULL THEN 'BoardEx'
            WHEN implied_end_date IS NOT NULL THEN 'Implied'
            WHEN implied_end_date IS NULL THEN 'Last Year'
        END AS end_date_source
    FROM director_old.term_end_dates),

other_directorships_dates AS (
    SELECT a.*,
        b.start_date, b.end_date, b.end_date_source,
        c.start_date AS other_start_date,
        c.end_date AS other_end_date,
        c.end_date_source AS other_end_date_source
    FROM other_directorships_w_gvkeys AS a
    INNER JOIN term_dates AS b
    USING (director_id)
    INNER JOIN term_dates AS c
    ON c.director_id = a.other_director_id),

other_dirs AS (
    SELECT DISTINCT b.*,
        (other_start_date, COALESCE(other_end_date, d.last_date))
            OVERLAPS
        (d.first_date, d.last_date) AS other_public_co,
        d.first_date AS other_first_date,
        d.last_date AS other_last_date
    FROM other_directorships_dates AS b
    LEFT JOIN stockdates AS d
    ON b.other_equilar_id=d.equilar_id),

--
director_gvkeys AS (
    SELECT DISTINCT director_id, test_date, gvkey, cik, test_date_type
    FROM director_old.director_gvkeys
    WHERE valid_date AND gvkey IS NOT NULL),

-- Choose the relevant "test date" for the other directorship
matched_other_fyr AS (
    SELECT a.director_id, a.fy_end, a.other_director_id,
        max(c.test_date) AS test_date
    FROM other_dirs AS a
    INNER JOIN filing_dates AS b
    USING (equilar_id, fy_end)
    LEFT JOIN director_gvkeys AS c
    ON a.other_director_id=c.director_id
        AND c.test_date <= b.date_filed
    GROUP BY 1, 2, 3),

-- Then add the GVKEY associated with that other "test date"
other_gvkeys AS (
    SELECT a.director_id, a.fy_end, a.other_director_id, a.test_date,
        b.test_date_type, b.gvkey AS other_gvkey, b.cik AS other_cik
    FROM matched_other_fyr AS a
    LEFT JOIN director_gvkeys AS b
    ON a.other_director_id=b.director_id AND
        a.test_date=b.test_date)

-- Add in data on other firm
SELECT a.*,
    b.test_date, b.test_date_type, b.other_gvkey, b.other_cik
    --, c.date_filed
FROM other_dirs AS a
INNER JOIN other_gvkeys AS b
USING (director_id, fy_end, other_director_id);
-- Exclude future directorships!!
-- WHERE date_filed >= other_start_date;

-- Do some database admin tasks (some for performance)
ALTER TABLE director_bio.other_directorships OWNER TO director_bio_team;
SET maintenance_work_mem='1GB';
CREATE INDEX ON director_bio.other_directorships (director_id);
CREATE INDEX ON director_bio.other_directorships (director_id, other_director_id);
CREATE INDEX ON director_bio.other_directorships (director_id, fy_end);
