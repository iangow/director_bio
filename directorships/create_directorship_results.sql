SET work_mem='3GB';

DROP TABLE IF EXISTS director_bio.directorship_results;

CREATE TABLE director_bio.directorship_results AS
SELECT DISTINCT b.*, a.director, d.result, d.non_match
FROM director_bio.bio_data AS a
INNER JOIN director_bio.other_directorships AS b
USING (director_id, fy_end)
INNER JOIN director_bio.regex_results AS d
USING (director_id, fy_end, other_director_id);

ALTER TABLE director_bio.directorship_results OWNER TO director_bio_team;
CREATE INDEX ON director_bio.directorship_results (director_id);
CREATE INDEX ON director_bio.directorship_results
    (director_id, other_directorships);
