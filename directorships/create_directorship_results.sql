SET work_mem='3GB';

DROP TABLE IF EXISTS director_bio.directorship_results;

CREATE TABLE director_bio.directorship_results AS
WITH

mult_permnos AS (
    SELECT DISTINCT director_id, fy_end, other_director_id,
        array_length(other_permnos, 1) > 1 AS mult_permnos
    FROM director_bio.other_directorships)

SELECT DISTINCT b.*, a.director, d.result, d.non_match, e.date_filed,
    c.mult_permnos
FROM director_bio.bio_data AS a
INNER JOIN director_bio.other_directorships AS b
USING (director_id, fy_end)
INNER JOIN mult_permnos AS c
USING (director_id, fy_end, other_director_id)
INNER JOIN director_bio.regex_results AS d
USING (file_name, director_id, other_director_id)
INNER JOIN filings.filings AS e
USING (file_name);

ALTER TABLE director_bio.directorship_results OWNER TO director_bio_team;
CREATE INDEX ON director_bio.directorship_results (director_id);
CREATE INDEX ON director_bio.directorship_results (director_id, other_directorships);
