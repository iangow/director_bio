source("tagging/filing_functions.R")

# Identify all cases tagged as "no_bios" and not involving DEF 14C filings ----
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())
sql <- "
    SELECT file_name, url, comment
    FROM director_bio.tagging_issues
    INNER JOIN filings.filings
    USING (file_name)
    WHERE 'no_bios' = ANY(issue_category_alt) AND form_type != 'DEF 14C';"

no_bios <- dbGetQuery(pg, sql)
rs <- dbDisconnect(pg)

# Download and process filings from SEC EDGAR ----
no_bios$have_text_file <- unlist(lapply(no_bios$file_name, get_text_file))
no_bios$extracted <- unlist(lapply(no_bios$file_name, extract.filings))

library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, "extracted", subset(no_bios, 
                                           select=c("file_name", "extracted")),
                   overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "
    INSERT INTO filings.extracted
    SELECT DISTINCT file_name 
    FROM extracted 
    WHERE 
        file_name NOT IN (
            SELECT file_name 
            FROM filings.extracted) 
        AND extracted;")
rs <- dbDisconnect(pg)

# Apply a simple regular expression to the filings to flag special meetings ----
no_bios$special_meeting <- 
    unlist(lapply(no_bios$file_name, check_special_meeting))
re_tag <- subset(no_bios, !special_meeting)

# Flag cases without bios for re-tagging ----
write.csv(re_tag, "~/Google Drive/director_bio/bio_tagging/re_tag.csv", 
          row.names = FALSE)
# I manually added these bios to the "remaining filing" sheet with a note 
# to re-tag them.