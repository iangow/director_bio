SET work_mem='5GB';

WITH 

disagreement AS (
    SELECT director_id_left::integer[], 
        director_id_right::integer[]
    FROM director_bio.mturk_data
    WHERE NOT agreement),

raw_data AS (
    SELECT ARRAY[director.equilar_id(director_id), director.director_id(director_id)] AS director_id,
	    array_agg(DISTINCT director_name) AS director_names, 
	    array_agg(DISTINCT company_name) AS companies,
        max(age) AS age,
        max(fy_end) AS fy_end,
	    array_agg(DISTINCT trim(director_bio)) AS director_bios
	FROM board.director
	WHERE director_id IS NOT NULL
	GROUP BY ARRAY[director.equilar_id(director_id), director.director_id(director_id)]
	ORDER BY director_names),
	
unnested_data AS (
        SELECT director_id,
		UNNEST(director_names) AS director_name,
		UNNEST(director_bios) AS director_bio,
        UNNEST(companies) AS company,
        age, fy_end
	FROM raw_data),
		
matched_director_bios AS (
	SELECT director_name, 
		'Company:       ' || a.company || E'\n' || 
        'Age (approx.): ' || a.age    || E'\n' || 
        'Fiscal year:   ' || a.fy_end || E'\n\n' || 
        'Biography: ' || a.director_bio AS director_bio_left,
		'Company:       ' || b.company || E'\n' || 
        'Age (approx.): ' || b.age    || E'\n' || 
        'Fiscal year:   ' || b.fy_end || E'\n\n' || 
        'Biography: ' || b.director_bio AS director_bio_right,
		a.director_id AS director_id_left,
		b.director_id AS director_id_right
	FROM unnested_data AS a
	INNER JOIN unnested_data AS b
	USING (director_name)
	WHERE a.director_id < b.director_id)

SELECT *
FROM matched_director_bios
INNER JOIN disagreement
USING (director_id_left, director_id_right);
