#!/usr/bin/env bash
Rscript tagging/get_es_data.R
Rscript tagging/create_bio_data.R
directorships/create_tagged_directorships.sh

