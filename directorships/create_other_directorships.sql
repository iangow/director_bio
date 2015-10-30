SET work_mem='5GB';

DROP TABLE IF EXISTS director_bio.other_directorships;

CREATE TABLE director_bio.other_directorships AS
WITH

company_names AS (
    SELECT DISTINCT director.equilar_id(company_id) AS equilar_id,
        fy_end, company, trim(cusip) AS cusip
    FROM director.co_fin),

matched_ids AS (
    SELECT director_id, (director_id).equilar_id,
        UNNEST(matched_ids) AS other_director_id,
	    (UNNEST(matched_ids)).equilar_id AS other_equilar_id
    FROM director.director_matches),

term_dates AS (
    SELECT (director.equilar_id(director_id),
            director.director_id(director_id))::equilar_director_id AS director_id,
        min(start_date) AS start_date,
        max(term_end_date) AS end_date
    FROM director.director
    GROUP BY 1),

other_directorships AS (
    SELECT DISTINCT director_id, fy_end,
        (director_id).equilar_id AS equilar_id,
        (other_director_id).equilar_id AS other_equilar_id,
        other_director_id,
        company AS other_directorship,
        cusip AS other_cusip
    FROM matched_ids
    INNER JOIN company_names
    USING (equilar_id)
    WHERE director_id != other_director_id),

-- Add CUSIP for main firm
other_directorships_w_cusip AS (
    SELECT DISTINCT a.*, b.cusip
    FROM other_directorships AS a
    INNER JOIN company_names AS b
    USING (equilar_id)),

other_directorships_dates AS (
    SELECT a.*, b.start_date, b.end_date,
        c.start_date AS other_start_date,
        c.end_date AS other_end_date
    FROM other_directorships_w_cusip AS a
    INNER JOIN term_dates AS b
    USING (director_id)
    INNER JOIN term_dates AS c
    ON c.director_id = a.other_director_id),

tagged_directorships AS (
    SELECT b.equilar_id AS other_equilar_id,
        upper(regexp_replace(as_tagged, '\s{2,}', ' ')) AS other_directorship_name
    FROM director_bio.tagged_directorships AS a
    INNER JOIN company_names AS b
    ON a.other_directorship=b.company),

original_names_unnest AS (
    SELECT equilar_id AS other_equilar_id,
        UNNEST(original_names) AS other_directorship_name
    FROM director.company_names
    UNION
    SELECT other_equilar_id, other_directorship_name
    FROM tagged_directorships),

original_names AS (
    SELECT other_equilar_id,
        array_agg(DISTINCT other_directorship_name) AS other_directorship_names
    FROM original_names_unnest
    GROUP BY 1),

stocknames AS (
    SELECT DISTINCT permno AS other_permno, ncusip AS other_cusip
    FROM crsp.stocknames),

stockdates AS (
    SELECT permno AS other_permno,
        min(namedt) AS other_first_date,
        max(nameenddt) AS other_last_date
    FROM crsp.stocknames
    GROUP BY 1)

SELECT *,
    (other_start_date, COALESCE(other_end_date, other_last_date))
        OVERLAPS
    (other_first_date, other_last_date) AS other_public_co
FROM other_directorships_dates AS b
INNER JOIN original_names
USING (other_equilar_id)
LEFT JOIN stocknames
USING (other_cusip)
LEFT JOIN stockdates
USING (other_permno);

ALTER TABLE director_bio.other_directorships OWNER TO director_bio_team;
CREATE INDEX ON director_bio.other_directorships (director_id);
CREATE INDEX ON director_bio.other_directorships (director_id, other_directorship);
