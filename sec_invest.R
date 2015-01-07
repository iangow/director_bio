# Connect to my database
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

sql <- paste(readLines("permno_cik.sql"), collapse="\n")
rs <- dbGetQuery(pg, sql)

# Now get the data
sql <- paste(readLines("sec_invest.sql"), collapse="\n")
rs <- dbGetQuery(pg, sql)

sec_invest_dirs <- 
    dbGetQuery(pg, "
        SET work_mem='3GB';
        
        WITH raw_data AS (
            SELECT director.parse_name(director) AS director_name, 
                director.equilar_id(director_id) AS equilar_id,
                director.director_id(director_id) AS equilar_director_id, 
                extract(year FROM fy_end)::integer AS year, 
                age, company
            FROM director.director),
            
        multiple_boards AS (
            SELECT (director_name).last_name, (director_name).first_name, 
                year, age, array_agg(equilar_id) AS equilar_ids,
                array_agg(equilar_director_id) AS equilar_director_ids,
                array_agg(company) AS companies
            FROM raw_data
            GROUP BY (director_name).last_name, (director_name).first_name, 
                year, age
            HAVING array_length(array_agg(equilar_director_id), 1) > 1
            ORDER BY (director_name).last_name, (director_name).first_name, 
                year, age),

        sec_invest_dirs AS (
            SELECT cik, equilar_id,
                unnest(director_ids) AS equilar_director_id,
                EXTRACT(year FROM date_filed)::integer AS year
            FROM director_bio.sec_invest),
               
        -- Get all proxy filings on EDGAR
        proxy_filings AS (
            SELECT cik::integer, 
                extract(year FROM date_filed) AS year, file_name
            FROM filings.filings
            WHERE form_type ~ '^DEF 14')

        SELECT a.cik, a.equilar_director_id, a.year, 
            array_agg(last_name) AS last_names, 
            array_agg(first_name) AS first_names,
            array_agg(file_name) AS file_names,
            array_agg(b.cik) AS ciks
        FROM sec_invest_dirs AS a
        INNER JOIN multiple_boards AS c
        ON a.equilar_director_id=ANY(c.equilar_director_ids)
            AND a.equilar_id=ANY(c.equilar_ids)
            AND a.year=c.year
        INNER JOIN proxy_filings AS b
        USING (cik, year)
        GROUP BY a.cik, a.equilar_director_id, a.year
        HAVING array_length(array_agg(file_name), 1) > 1")

dbDisconnect(pg)

write.csv(sec_invest_dirs, "data/sec_invest_dirs.csv")
