# Utility functions ----
apply_regex <- function(file_path, regex, ignore.case=FALSE) {
    
    if (grepl(".html?$", file_path)) {
        # If HTML
        text <- html2txt(file_path)
    } else {
        # If text
        text <- paste(readLines(file_path), collapse="\n")
    }
    
    length(grep(regex, text, perl=TRUE, ignore.case=ignore.case))>0
}

get_file_list <- function(file_path) {
    
    # Function to get a list of the files associated with a filing
    
    # Files associated with a filing go in a directory with a related name
    root.path <- gsub("(\\d{10})-(\\d{2})-(\\d{6})\\.txt", "\\1\\2\\3", file_path)
    
    if (file.exists(root.path)) {
        # Currently, the code only looks for HTML and text files
        files <- list.files(path = root.path, pattern="(txt|htm|html)$", 
                            full.names = TRUE)
    } else {
        # If there is no directory at root.path, there is just the single
        # complete text submission file
        files <- file_path
    }
    if (length(files)==0) return(file_path)
    
    return(files)
}

# Code applying regular expressions, etc. ----
# Look at the first filing (change 1 to 2, etc., to get second, etc.)
# browseFiling(1)

check_regexes <- function(file_name, regexes) {
    path <- file.path(Sys.getenv("EDGAR_DIR"), file_name)
    
    files <- get_file_list(path)
    if (length(files)==0) return(NA)
    
    # If any regular expression applies ...
    regex <- paste0("(", paste(regexes, collapse="|"), ")")
    
    # Generalize spaces (sometimes spaces aren't simply spaces)
    # Note that the first and second arguments here behave differently.
    # The first detects multiple spaces (including carriage returns) in the
    # base regular expression;
    # the second inserts a regular expression version of spaces to make 
    # a more robust regular expression.
    regex <- gsub("\\s+", "\\\\s+", regex)
    
    return(any(mapply(apply_regex, files, regex, ignore.case=TRUE)))
}

library(devtools)
source_url(paste0("https://raw.githubusercontent.com/iangow/acct_data/",
                  "master/filings/download_filing_functions.R"))

