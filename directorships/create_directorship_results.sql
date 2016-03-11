SET work_mem='3GB';

DROP TABLE IF EXISTS director_bio.directorship_results;

CREATE TABLE director_bio.directorship_results AS
WITH

all_data AS (
    SELECT DISTINCT b.*, a.director, d.result, d.non_match
    FROM director_bio.bio_data AS a
    INNER JOIN director_bio.other_directorships AS b
    USING (director_id, fy_end)
    INNER JOIN director_bio.regex_results AS d
    USING (director_id, fy_end, other_director_id))

SELECT *,
    other_end_date < date_filed OR date_filed IS NULL AS past,
    date_filed < other_start_date OR other_start_date IS NULL AS future,
    COALESCE(((other_end_date <= other_last_date OR other_last_date IS NULL) AND
        (other_end_date >= other_first_date OR other_end_date IS NULL)) OR
        ((other_start_date <= other_last_date OR other_last_date IS NULL) AND
        (other_start_date >= other_first_date OR other_start_date IS NULL)), FALSE) AS public_at_ten,
     other_cik IS NOT NULL AND cik IS NOT NULL AS not_missing_cik,
     COALESCE((other_first_date <= date_filed OR date_filed IS NULL) AND
        (other_last_date>= date_filed OR other_last_date IS NULL), FALSE) AS public_at_disc,
     date_filed >= '2010-03-01' AS post_regulation
FROM all_data;

ALTER TABLE director_bio.directorship_results OWNER TO director_bio_team;
CREATE INDEX ON director_bio.directorship_results (director_id);
CREATE INDEX ON director_bio.directorship_results
    (director_id, other_directorships);
