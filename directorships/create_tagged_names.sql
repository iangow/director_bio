DROP TABLE IF EXISTS director_bio.tagged_names;

CREATE TABLE director_bio.tagged_names AS

WITH companies AS (
    SELECT DISTINCT director_old.equilar_id(company_id), company
    FROM director_old.co_fin),

tagged_directorships AS (
    SELECT b.equilar_id AS other_equilar_id,
        -- Convert name to upper case, convert multiple spaces to single spaces
        array_agg(DISTINCT upper(regexp_replace(as_tagged, '\s{2,}', ' '))) AS tagged_names
    FROM director_bio.tagged_directorships AS a
    LEFT JOIN companies AS b
    ON a.other_directorship=b.company
    WHERE other_directorship !=''
    GROUP BY 1)

SELECT DISTINCT other_equilar_id, tagged_names
FROM tagged_directorships;

CREATE INDEX ON director_bio.tagged_names (other_equilar_id);

ALTER TABLE director_bio.tagged_names OWNER TO director_bio_team;

