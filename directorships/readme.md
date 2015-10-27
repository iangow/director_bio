# Directorships

The code in this directorory relates to the identification of directorships disclosed or not disclosed in director biographies in proxy filings.

## Identifying other directorships

The first task is to identify other directorships that are held by a director of a given firm.
The code in `create_other_directorships.sql` does this. 
This code relies on the table `director.director_matches`, which is created by code [here](https://github.com/iangow/acct_data/blob/master/director/match_directors.sql).
The end result of this code is the table `director_bio.other_directorships`.
The SQL in `create_other_directorships.sql` can be run (e.g., from within RStudio Server) by running `create_other_directorships.sh`

The table `director_bio.other_directorships` also contains data on names associated with the firm with which the other directorship
is held. 

## Tagging other directorships

Code in `create_tagged_directorships.sql` extracts data from `director_bio.raw_tagging_data` to create `director_bio.tagged_directorships`. 
Data in `director_bio.tagged_directorships` is used to create `director_bio.other_directorships`, as the tagged names are a useful resource for searching for other directorships in biographies.
The SQL in `create_tagged_directorships.sql` can be run (e.g., from within RStudio Server) by running `create_tagged_directorships.sh`

## Identifying whether other directorships are disclosed

Code in `directorship_regex_apply_full.py` uses regular-expression code in `directorship_regex.py` to try to determine whether a
given other directorship is mentioned in a director's biography provided by another firm.
