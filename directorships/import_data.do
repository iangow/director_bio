#delimit ;

local sql "
    SELECT *, 
		CASE WHEN other_first_date <= other_start_date 
			AND other_last_date>=date_filed
			THEN 'always_public' 
			ELSE '' END AS public_status
    FROM director_bio.directorship_results
    WHERE non_match AND start_date < date_filed
		AND gvkey IS NOT NULL AND other_gvkey IS NOT NULL";

odbc load, exec("`sql'") dsn("iangow") clear;

compress;
destring directorid_issue non_match other_public_co, replace;
 
