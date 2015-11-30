# Updating tagging data

The script [`tagging/process_tagging_data.sh`](process_tagging_data.sh) runs the following steps:

- Scrape data from ElasticSearch with [`tagging/get_es_data.R`](get_es_data.R).
- Extract bio data with [`tagging/create_bio_data.R`](create_bio_data.R).
- Extract directorship data with [`directorships/create_tagged_directorships.sh`](../directorships/create_tagged_directorships.sh).

Then the directorship data is updated 

- Apply regular expressions to bios with [`directorships/directorship_regex_apply_full.py`](../directorships/directorship_regex_apply_full.py).
- Merge results with [`directorships/create_directorship_results.R`](../directorships/create_directorship_results.R).
