# Updating tagging data

- Scrape data from ElasticSearch with [`tagging/get_es_data.R`](tagging/get_es_data.R).
- Extract bio data with [`tagging/create_bio_data.R`](tagging/create_bio_data.R).
- Extract directorship data with [`directorships/create_tagged_directorships.sh`](directorships/create_tagged_directorships.sh).
- Apply regular expressions to bios with [`directorships/directorship_regex_apply_full.py`](directorships/directorship_regex_apply_full.py).
- Merge results with [`directorships/create_directorship_results.R`](directorships/create_directorship_results.R).
