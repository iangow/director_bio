# Code related to project on director bios

## Code to identify extreme events

- Restatements with SEC investigations (`sec_invest.sql`)
- Bankrupctcies (`bankrupt.sql`)
- Litigation (`legal.sql`)

## Code to match directors on boards subject to extreme events to proxy filings

- Code in `sec_invest.R` does this for restatements with SEC investigations. 
This code depends on `sec_invest.sql` (above) and `sec_invest_dirs.sql`, 
as well as data in Equilar (see the [Github repository](https://github.com/iangow/acct_data/tree/master/equilar)).

## Code to match directors on multiple boards using director name and age

- Code in `match_bios.R` does this; depends on `match_bios.sql`, 
as well as data in Equilar (see the [Github repository](https://github.com/iangow/acct_data/tree/master/equilar)).
