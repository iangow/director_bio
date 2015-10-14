SET work_mem='5GB';

-- The main way to tell whether a directorship is mentioned or not is
-- the XPath in the "ranges.start" field.
-- If the XPath contains "/ul/li" we know the directorship is not mentioned.
-- If the XPath contains "/pre" then we know the directorship was mentioned.
DROP TABLE IF EXISTS director_bio.tagged_directorships;

CREATE TABLE director_bio.tagged_directorships AS
WITH

tagged_data AS (
    SELECT file_name, -- get director_id from uri,
        uri,
        regexp_replace(uri,
                        '.*ships/\d+/\d+/(.*)', '\1') AS director_id,
        director AS other_directorship,
        CASE
            WHEN ranges->>'start' ~ '/pre' THEN TRUE
            WHEN ranges->>'start' ~ '/ul/li' THEN FALSE
        END AS directorship_present,
        regexp_replace(regexp_replace(quote, '\n', ' '), '\s+', ' ')
            AS as_tagged
    FROM director_bio.raw_tagging_data
    WHERE category='directorships' AND director != 'Company Not Found'
        AND uri ~ '.*ships/\d+/\d+/(.*)'),

tagged_data_ids AS (
    SELECT (director.equilar_id(director_id),
        director.director_id(director_id))::equilar_director_id AS director_id,
        director.equilar_id(director_id) AS equilar_id,
        file_name, other_directorship, directorship_present,
        as_tagged, uri
    FROM tagged_data)

SELECT *
FROM tagged_data_ids;

CREATE INDEX ON director_bio.tagged_directorships (file_name);
CREATE INDEX ON director_bio.tagged_directorships (director_id);
