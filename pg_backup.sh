#!/usr/bin/env bash
pg_dump --host iangow.me --format custom --no-tablespaces -O --verbose --table "public.mirror_filing" "crsp" \
   --file ~/Dropbox/pg_private/director_bio/mirror_filings.backup
pg_dump --host iangow.me --format custom --no-tablespaces -O --verbose --table "public.mirror_biography" "crsp" \
   --file ~/Dropbox/pg_private/director_bio/mirror_biography.backup
pg_dump --host iangow.me --format custom --no-tablespaces -O --verbose --schema "public" "crsp" \
   --file ~/Dropbox/pg_private/director_bio/public.backup
pg_dump --host iangow.me --format custom --no-tablespaces -O --verbose --schema "director_bio" "crsp" \
   --file ~/Dropbox/pg_private/director_bio/director_bio.backup

