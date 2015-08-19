# Small function to create URL from EDGAR's file_name variable
makeURL <- function(file_name) {
    if(is.na(file_name)) return(NA)
    temp <- gsub("(\\d{10})-(\\d{2})-(\\d{6})\\.txt", "\\1\\2\\3",
                 file_name)
    paste0("http://www.sec.gov/Archives/", temp)
}

# Collect data on "restatement directors" ----
# Restatement directors are directors on boards of firms having a
# restatement involving an SEC investigation.

# Connect to my database
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

# Now get the data
sql <- paste(readLines("bad_stuff_samples/sec_invest.sql"), collapse="\n")
rs <- dbGetQuery(pg, sql)

sql <- paste(readLines("bad_stuff_samples/sec_invest_dirs.sql"), collapse="\n")
rs <- dbGetQuery(pg, sql)

sec_invest_dirs <- dbGetQuery(pg, "SELECT * FROM director_bio.sec_invest_dirs")
rs <- dbDisconnect(pg)

# Save to Google Drive
write.csv(sec_invest_dirs, 
          "~/Google Drive/director_bio/sec_invest_dirs.csv", row.names=FALSE)

# Collect data on restatement directors on multiple boards ----
# Collect links to proxies, etc.

# This query breaks out each observation ('UNNEST') into separate rows
# and restricts the sample to cases where the director serves on multiple
# boards.
pg <- dbConnect(PostgreSQL())

sec_invest_proxies <- dbGetQuery(pg, "
    SET work_mem='3GB';
   
    SELECT cik, file_date, last_name, first_name, 
        UNNEST(proxy_filings) AS proxy_filing,
        UNNEST(equilar_ids) AS equilar_id,
        UNNEST(next_proxy_filings) AS next_proxy_filings
    FROM director_bio.sec_invest_dirs
    WHERE num_boards>1")

rs <- dbDisconnect(pg)

# Clean up variables
sec_invest_proxies$url <- unlist(lapply(sec_invest_proxies$proxy_filing, makeURL))
sec_invest_proxies$url_next <- 
    unlist(lapply(sec_invest_proxies$next_proxy_filing, makeURL))
sec_invest_proxies$next_proxy_filing <- NULL
    
# Save to Google Drive.
write.csv(sec_invest_proxies,
          "~/Google Drive/director_bio/sec_invest_proxies.csv", row.names=FALSE)
