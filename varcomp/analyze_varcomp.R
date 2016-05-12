# Code to calculate variance components

# Download data ----
download.file("https://www.dropbox.com/s/gd9qmda2xzzw7u1/temp_adverse.dta",
              destfile = "varcomp/temp_adverse.dta")

# Load data ----
library(haven)
library(dplyr)
tbl_vd <-
    read_dta("varcomp/temp_adverse.dta") %>%
    as_data_frame() %>%
    select(director_id, fy_end, other_director_id,
           directorid, year, gvkey, non_match) %>%
    mutate(year=as.integer(year),
           directorid=as.integer(directorid))

count_distinct <- function(data, var) {
    data %>% select_(var) %>% distinct() %>% summarize(n=n())
}

# Calculate summary statistics
count_distinct <- function(data, var) {
    data %>% select_(var) %>% distinct() %>% summarize(n=n())
}

tbl_vd %>% count_distinct("gvkey")
tbl_vd %>% count_distinct("directorid")
tbl_vd %>% count_distinct("year")

# Estimate variance components ----
df_vd <- tbl_vd %>% as.data.frame()

# Package chosen because it claims to use similar approach to PROC VARCOMP
library(VCA)

# This is fine
vcf_year <- anovaVCA(non_match ~ year, df_vd)

# This requires more than 40GB of RAM
vcf_firm <- anovaVCA(non_match ~ gvkey, df_vd)

# Haven't event tried this one
vcf_all <- anovaVCA(non_match ~ year + gvkey + directorid, df_vd)

# This one may be asking too much
vcf_all_interacted <- anovaVCA(non_match ~ year * gvkey * directorid, df_vd)
