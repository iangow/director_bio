SET work_mem='5GB';

WITH 

raw_data AS (
    SELECT ARRAY[director.equilar_id(director_id), director.director_id(director_id)] AS director_id,
	    array_agg(DISTINCT director_name) AS director_names, 
	    array_agg(DISTINCT company_name) AS companies,
        array_agg(DISTINCT age) AS ages,
	    array_agg(DISTINCT trim(director_bio)) AS director_bios
	FROM board.director
	WHERE director_id IS NOT NULL
	GROUP BY ARRAY[director.equilar_id(director_id), director.director_id(director_id)]
	ORDER BY director_names),
	
unnested_data AS (
        SELECT director_id,
		UNNEST(director_names) AS director_name,
		UNNEST(director_bios) AS director_bio,
        UNNEST(companies) AS company
	FROM raw_data),
		
matched_director_bios AS (
	SELECT director_name, 
		'Company: ' || a.company || '\n\n' || 
            a.director_bio AS director_bio_left,
		'Company: ' || b.company || '\n\n' ||
            b.director_bio AS director_bio_right,
		a.director_id AS director_id_left,
		b.director_id AS director_id_right
	FROM unnested_data AS a
	INNER JOIN unnested_data AS b
	USING (director_name)
	WHERE a.director_id < b.director_id)

SELECT *
FROM matched_director_bios;
