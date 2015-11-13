SET work_mem='5GB';

DROP TABLE IF EXISTS director_bio.other_directorships;

CREATE TABLE director_bio.other_directorships AS
WITH

director AS (
    SELECT DISTINCT (director.equilar_id(director_id),
            director.director_id(director_id))::equilar_director_id AS director_id,
        director.equilar_id(director_id), fy_end
    FROM director.director),

db_merge AS (
    SELECT equilar_id, fy_end, cusip, companies, cik, gvkeys
    FROM director.db_merge),

matched_ids AS (
    SELECT director_id, (director_id).equilar_id,
        UNNEST(matched_ids) AS other_director_id,
	    (UNNEST(matched_ids)).equilar_id AS other_equilar_id,
	    directorid
    FROM director.director_matches),

term_dates AS (
    SELECT (director.equilar_id(director_id),
            director.director_id(director_id))::equilar_director_id AS director_id,
        min(start_date) AS start_date,
        max(term_end_date) AS end_date
    FROM director.director
    GROUP BY 1),

other_directorships AS (
    SELECT DISTINCT
        a.director_id, a.fy_end, a.equilar_id,

        -- Identifiers for "this" company
        b.companies,
        b.cusip, b.gvkeys, b.cik,

        -- Matched director-level data
        c.directorid,
        (c.other_director_id).equilar_id AS other_equilar_id,
        c.other_director_id,

        -- Identifiers for the "other" company
        d.companies AS other_directorships,
        d.cusip AS other_cusip,
        d.cik AS other_cik,
        d.gvkeys AS other_gvkeys
    FROM director AS a
    INNER JOIN db_merge AS b
    USING (equilar_id, fy_end)
    INNER JOIN matched_ids AS c
    USING (director_id)
    LEFT JOIN db_merge AS d
    ON (other_director_id).equilar_id=d.equilar_id
    WHERE director_id != other_director_id),

other_directorships_dates AS (
    SELECT a.*,
        b.start_date, b.end_date,
        c.start_date AS other_start_date,
        c.end_date AS other_end_date
    FROM other_directorships AS a
    INNER JOIN term_dates AS b
    USING (director_id)
    LEFT JOIN term_dates AS c
    ON c.director_id = a.other_director_id),

original_names AS (
    SELECT DISTINCT director.equilar_id(company_id) AS other_equilar_id,
        array_agg(DISTINCT company) AS other_directorship_names
    FROM director.co_fin
    GROUP BY 1),

stockdates AS (
    SELECT other_equilar_id,
        array_agg(DISTINCT permno) AS other_permnos,
        min(namedt) AS other_first_date,
        max(nameenddt) AS other_last_date
    FROM crsp.stocknames AS a
    INNER JOIN (
        SELECT DISTINCT equilar_id AS other_equilar_id, cusip AS ncusip
        FROM db_merge) AS b
    USING (ncusip)
    GROUP BY 1),

dupes AS (
    SELECT director_id, count(*) > 1 AS directorid_issue
    FROM director.director_matches
    GROUP BY director_id)

SELECT DISTINCT *,
    (other_start_date, COALESCE(other_end_date, other_last_date))
        OVERLAPS
    (other_first_date, other_last_date) AS other_public_co
FROM other_directorships_dates AS b
INNER JOIN original_names
USING (other_equilar_id)
LEFT JOIN stockdates
USING (other_equilar_id)
INNER JOIN dupes
USING (director_id);

ALTER TABLE director_bio.other_directorships OWNER TO director_bio_team;

SET maintenance_work_mem='1GB';
CREATE INDEX ON director_bio.other_directorships (director_id);
CREATE INDEX ON director_bio.other_directorships (director_id, other_directorships);
CREATE INDEX ON director_bio.other_directorships (director_id, fy_end);
