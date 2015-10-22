SELECT (other_director_id::equilar_director_id).equilar_id, 
    sum(non_match::integer) AS num_non_matches,
    sum(non_match::integer)/count(non_match)::float8 AS prop_non_matches,
    array_agg(DISTINCT other_directorship) AS other_directorship_names
FROM director_bio.directorship_results
GROUP BY 1
ORDER BY 2 DESC
LIMIT 100;

