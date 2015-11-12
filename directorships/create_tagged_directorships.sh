#!/usr/bin/env bash
psql -f directorships/create_tagged_directorships.sql
psql -f directorships/create_tagged_names.sql
