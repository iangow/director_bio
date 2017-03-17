SET work_mem='5GB';

DROP TABLE IF EXISTS director_bio.bio_data;

CREATE TABLE director_bio.bio_data AS
WITH

directors AS (
    SELECT director_old.equilar_id(director_id) AS equilar_id,
        director_old.director_id(director_id) AS director_id,
        fy_end, director
    FROM director_old.director),

proxy_filings AS (
    SELECT DISTINCT equilar_id, fy_end, file_name
    FROM director_old.equilar_proxies
    WHERE file_name IS NOT NULL),

directors_w_proxies AS (
    SELECT equilar_id, director_id, fy_end, director, file_name
    FROM directors
    INNER JOIN proxy_filings
    USING (equilar_id, fy_end)),

bio_data_raw AS (
    SELECT director, file_name,
        string_agg(quote, ' ' ORDER BY updated) AS bio
    FROM director_bio.raw_tagging_data AS a
    WHERE category='bio'
    GROUP BY director, file_name),

bio_data AS (
    SELECT a.*, b.equilar_id, b.director_id, b.fy_end, c.date_filed
    FROM bio_data_raw AS a
    INNER JOIN directors_w_proxies AS b
    USING (director, file_name)
    INNER JOIN filings.filings AS c
    USING (file_name)),

-- Get the earliest filing with a matching bio
first_bio AS (
    SELECT equilar_id, director_id, fy_end, min(date_filed) AS date_filed
    FROM bio_data
    GROUP BY equilar_id, director_id, fy_end),

-- If there are multiple proxy filings on the same date, they're probably
-- identical, so we just choose one 'at random'
random_bio AS (
    SELECT equilar_id, director_id, fy_end, min(file_name) AS file_name
    FROM bio_data
    INNER JOIN first_bio
    USING (equilar_id, director_id, fy_end, date_filed)
    GROUP BY equilar_id, director_id, fy_end)

SELECT *
FROM bio_data
INNER JOIN random_bio
USING (equilar_id, director_id, fy_end, file_name);

ALTER TABLE director_bio.bio_data
    ALTER COLUMN director_id TYPE equilar_director_id
        USING (equilar_id, director_id)::equilar_director_id;

ALTER TABLE director_bio.bio_data OWNER TO director_bio_team;
GRANT SELECT ON director_bio.bio_data TO jheese;

CREATE INDEX ON director_bio.bio_data (file_name);
CREATE INDEX ON director_bio.bio_data (director_id, fy_end);
