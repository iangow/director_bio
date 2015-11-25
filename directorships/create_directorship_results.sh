#!/usr/bin/env bash
directorships/directorship_regex_apply_full.py;
psql -f directorships/create_directorship_results.sql;
R CMD BATCH -f directorships/frequent_non_matches.R;
