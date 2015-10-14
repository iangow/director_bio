SET work_mem='5GB';

DROP TABLE IF EXISTS director_bio.other_directorships;

CREATE TABLE director_bio.other_directorships AS
WITH company_names AS (
    SELECT DISTINCT director.equilar_id(company_id), company
    FROM director.co_fin),

matched_ids AS (
    SELECT director_id, UNNEST(matched_ids) AS other_director_id,
	(UNNEST(matched_ids)).equilar_id
    FROM director.director_matches),

other_directorships AS (
    SELECT DISTINCT director_id,
        (other_director_id).equilar_id AS other_equilar_id,
        other_director_id,
        company AS other_directorship
    FROM matched_ids
    INNER JOIN company_names
    USING (equilar_id)
    WHERE director_id != other_director_id),

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
    GROUP BY 1)

SELECT *
FROM other_directorships AS b
INNER JOIN original_names
USING (other_equilar_id);

CREATE INDEX ON director_bio.other_directorships (director_id);
CREATE INDEX ON director_bio.other_directorships (director_id, other_directorship);
