# This function maps from the "file_name" to the URL on Andrew's server
get_bio_url <- function(file_name) {
    gsub("edgar/data/(\\d+)/(\\d{10})-(\\d{2})-(\\d{6})\\.txt",
         "http://hal.marder.io/highlight/\\1/\\2\\3\\4", file_name)
}

# dplyr is an awesome package for playing around with data. Google it; there are
# many online tutorials, etc.
library(dplyr)
pg <- src_postgres()

# The code in tagging/bio_tagging_issues.R imports the data from the
# Google Sheets and puts it in the table director_bio.tagging_issues.
tagging_issues <- tbl(pg, sql("SELECT * FROM director_bio.tagging_issues"))

# The code in tagging/get_es_data.R puts data from Andrew's server and puts it
# director_bio.raw_tagging_data. Code in tagging/create_bio_data.R then cleans
# up and filters this data and puts it into director_bio.bio_data.
bio_data <- tbl(pg, sql("
    SELECT equilar_id, (director_id).director_id, fy_end, director, bio
    FROM director_bio.bio_data"))

# This table maps from Equilar firm-years to proxy filings. It is created using
# code at in the repository at https://github.com/iangow/acct_data under
# director/create_equilar_proxies.sql.
equilar_proxies <- tbl(pg, sql("
    SELECT *
    FROM director.equilar_proxies
    WHERE file_name IS NOT NULL"))

# The <- puts the results of the code into the data frame untagged_firm_years
# The %>% is the dplyr "pipe" operator.
untagged_firm_years <-
    equilar_proxies %>%                   # Mapped to proxy filings
    anti_join(bio_data) %>%               # ... but no tagged bios
    anti_join(tagging_issues) %>%         # ... and no tagging issues.
    arrange(equilar_id, fy_end) %>%       # Sort the data,
    collect() %>%                         # ... "collect" to apply R function
    mutate(url = get_bio_url(file_name))  # Add URL on Andrew's server

# Open up the URL (on Andrew's server) for the first filing. Changing the number
# from 1 to 2 opens the second, and so on.
browseURL(untagged_firm_years$url[1])

