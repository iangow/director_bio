SET work_mem='5GB';

DROP TABLE IF EXISTS director_bio.directorship_results;

CREATE TABLE director_bio.directorship_results AS
WITH raw_data AS (
    SELECT b.*, a.director, c.result, c.non_match, d.date_filed
    FROM director_bio.bio_data AS a
    INNER JOIN director_bio.other_directorships AS b
    USING (director_id, fy_end)
    INNER JOIN director_bio.regex_results AS c
    USING (file_name, director_id, other_director_id)
    INNER JOIN filings.filings AS d
    USING (file_name)),

mult_permnos AS (
    SELECT director_id, fy_end, other_director_id,
        count(DISTINCT other_permno) > 1 AS mult_permnos
    FROM raw_data
    GROUP BY director_id, fy_end, other_director_id)

SELECT *
FROM raw_data
INNER JOIN mult_permnos
USING (director_id, fy_end, other_director_id);

ALTER TABLE director_bio.directorship_results OWNER TO director_bio_team;
CREATE INDEX ON director_bio.directorship_results (director_id);
CREATE INDEX ON director_bio.directorship_results (director_id, other_directorship);
