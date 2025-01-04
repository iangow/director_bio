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

## Google Sheets documents

 - [`non_matches`](https://docs.google.com/spreadsheets/d/1L0XqboEEMMkbPH5PBc3rWxDkOMnXCT5EhZ7dsUDFnmM)
 - [Director bio tagging issues](https://docs.google.com/spreadsheets/d/1B58Z9MEZsV69MFLIBv8DEv3sddScBYAKY2yM4ggihVo)
- [`missing_bios_2.xlsx`](https://docs.google.com/spreadsheets/d/1z8x9Owt_ztjCukYEpkc5pDD2vPOQJvrTA9UvW90cgmo/edit?gid=415833271#gid=415833271)
- [`test_samples`](https://docs.google.com/spreadsheets/d/16lq6rFmBUDoALvzAItTxcytVMEDv4yqOGmLFkoJrOqE/edit?gid=372427779#gid=372427779)
- [`to_retag`](https://docs.google.com/spreadsheets/d/1PIEYkDnH7cgdelzcLipdw8H9p7Z5dbeg521POfLFhLw)
