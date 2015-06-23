#!/usr/bin/env bash
pg_dump --host iangow.me --format custom --no-tablespaces -O --verbose --table "public.mirror_filing" "crsp" --file ~/Dropbox/pg_private/mirror_filings.backup
pg_dump --host iangow.me --format custom --no-tablespaces -O --verbose --table "public.mirror_filing" "crsp" --file ~/Dropbox/pg_private/mirror_biography.backup
pg_dump --host iangow.me --format custom --no-tablespaces -O --verbose --schema "public" "crsp" --file ~/Dropbox/pg_private/public.backup

