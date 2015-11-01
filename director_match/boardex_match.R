library(dplyr)
pg <- src_postgres()

# Use CRSP to match tickers and CUSIPs to PERMNOs ----
stocknames <- tbl(pg, sql("
    SELECT permno, comnam, namedt, nameenddt, ncusip AS cusip, ticker
    FROM crsp.stocknames"))

crsp_cusips <-
    stocknames %>%
    select(permno, cusip) %>%
    distinct()

crsp_tickers <-
    stocknames %>%
    select(permno, ticker, namedt, nameenddt) %>%
    group_by(permno, ticker) %>%
    summarize(start_date=min(namedt), end_date=max(nameenddt))

# Match Equilar to CRSP PERMNOs where possible ----
director_ciks <- tbl(pg, sql("
    SELECT *
    FROM director.ciks")) %>%
    select(equilar_id, cusip, cik) %>%
    distinct()

co_fin <- tbl(pg, sql("
    SELECT director.equilar_id(company_id),
        substring(cusip from 1 for 8) AS cusip8, *
    FROM director.co_fin")) %>%
    rename(cusip_original=cusip) %>%
    rename(cusip=cusip8)

director_cusip <-
    co_fin %>%
    inner_join(crsp_cusips) %>%
    select(equilar_id, cusip, permno) %>%
    distinct() %>%
    mutate(match_type=sql("'cusip'::text"))

director_ticker <-
    co_fin %>%
    anti_join(director_cusip) %>%
    left_join(crsp_tickers) %>%
    filter((fy_end >= start_date & fy_end <= end_date) | is.na(start_date)) %>%
    select(equilar_id, cusip, permno) %>%
    distinct() %>%
    mutate(match_type=sql("'ticker'::text"))

director_permno <-
    director_cusip %>%
    union(director_ticker) %>%
    collect()

director_permno$match_type[is.na(director_permno$permno)] <- "none"
table(director_permno$match_type)

# Match BoardEx to CRSP PERMNOs where possible ----

# BoardEx companies
co_profile <- tbl(pg, sql("
    SELECT DISTINCT boardid, ticker,
        regexp_replace(isin, '^(?:CA|US)([A-Z0-9]{8}).*$', '\\1') AS cusip
    FROM boardex.company_profile_stocks
    WHERE isin ~ '^(CA|US)'"))

co_profile_cusip <-
    co_profile %>%
    inner_join(crsp_cusips) %>%
    select(boardid, cusip, permno) %>%
    distinct() %>%
    mutate(match_type=sql("'cusip'::text"))

co_profile_ticker <-
    co_profile %>%
    anti_join(co_profile_cusip) %>%
    left_join(crsp_tickers) %>%
    # filter(fy_end >= start_date, fy_end <= end_date) %>%
    select(boardid, cusip, permno) %>%
    distinct() %>%
    mutate(match_type=sql("'ticker'::text"))

co_profile_permno <-
    co_profile_cusip %>%
    union(co_profile_ticker) %>%
    distinct() %>%
    collect()

co_profile_permno$match_type[is.na(co_profile_permno$permno)] <- "none"
table(co_profile_permno$match_type)

# Combine Equilar and BoardEx using CUSIPs and PERMNOs ----
boardex_merge_cusip <-
    director_permno %>%
    select(equilar_id, cusip) %>%
    left_join(co_profile_permno %>% select(boardid, cusip),
              by="cusip") %>%
    select(equilar_id, boardid) %>%
    distinct() %>%
    mutate(match_type="cusip")

boardex_merge_permno <-
    director_permno %>%
    anti_join(boardex_merge_cusip) %>%
    select(equilar_id, permno) %>%
    filter(!is.na(permno)) %>%
    left_join(co_profile_permno %>%
                  select(boardid, permno)) %>%
    select(equilar_id, boardid) %>%
    distinct() %>%
    mutate(match_type="permno")

boardex_merge <-
    boardex_merge_cusip %>%
    union(boardex_merge_permno) %>%
    collect()

boardex_merge$match_type[is.na(boardex_merge$boardid)] <- "none"
table(boardex_merge$match_type)
