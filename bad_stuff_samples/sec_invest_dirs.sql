SET work_mem='3GB';

DROP TABLE IF EXISTS director_bio.sec_invest_dirs;

CREATE TABLE director_bio.sec_invest_dirs AS 
WITH raw_data AS (
    SELECT director.parse_name(director) AS director_name, 
        director.equilar_id(director_id) AS equilar_id,
        fy_end,
        director.director_id(director_id) AS equilar_director_id, 
        extract(year FROM fy_end)::integer AS year, 
        age, company
    FROM director.director),
    
raw_data_w_proxies AS (
    SELECT *, lead(file_name) OVER w AS next_proxy_filing
    FROM raw_data
    INNER JOIN director.equilar_proxies
    USING (equilar_id, fy_end)
    WINDOW w AS (PARTITION BY equilar_id ORDER BY fy_end)),

multiple_boards AS (
    SELECT (director_name).last_name, (director_name).first_name, 
        year, age, array_agg(equilar_id) AS equilar_ids,
        array_agg(fy_end) AS fy_ends,
        array_agg(equilar_director_id) AS equilar_director_ids,
        array_agg(company) AS companies,
        array_agg(file_name) AS proxy_filings,
        array_agg(next_proxy_filing) AS next_proxy_filings,
        array_length(array_agg(equilar_director_id), 1)  AS num_boards
    FROM raw_data_w_proxies
    GROUP BY (director_name).last_name, (director_name).first_name, 
        year, age)
       
SELECT *
FROM director_bio.sec_invest AS a
INNER JOIN multiple_boards AS c
ON a.equilar_id=ANY(c.equilar_ids) 
    AND a.fy_end=ANY(c.fy_ends)
ORDER BY cik, file_date, last_name, first_name
