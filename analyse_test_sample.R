library(dplyr)
library(RPostgreSQL)
pg <- src_postgres()

rs <- dbGetQuery(pg$con, "SET work_mem='1GB'")

raw_tagging_data <-
    tbl(pg, sql("SELECT * FROM director_bio.raw_tagging_data"))

test_sample <-
    tbl(pg, sql("SELECT * FROM director_bio.test_sample"))

bio_data <-
    tbl(pg, sql("SELECT * FROM director_bio.bio_data"))

regex_results <-
    tbl(pg, sql("SELECT * FROM director_bio.regex_results"))

directorship_results <-
    tbl(pg, sql("SELECT * FROM director_bio.directorship_results"))

who_tagged <-
    raw_tagging_data %>%
    filter(category == 'bio') %>%
    inner_join(bio_data) %>%
    group_by(director_id, fy_end) %>%
    summarize(tagged_by = sql("array_agg(DISTINCT username)")) %>%
    ungroup() %>%
    compute()

tagging_issues <-
    who_tagged %>%
    inner_join(bio_data) %>%
    inner_join(test_sample) %>%
    semi_join(
        directorship_results %>%
            filter(non_match, !future, !past))

tagging_issues %>%
    filter(proposed_resolution == "tag_bio") %>%
    mutate(tagger = unnest(tagged_by)) %>%
    group_by(tagger) %>%
    summarize(count = n()) %>%
    arrange(desc(count))

regex_results %>%
    semi_join(
        directorship_results %>%
            filter(non_match, !future, !past) %>%
            select(director_id, fy_end, other_director_id)) %>%
    inner_join(who_tagged) %>%
    mutate(tagged_by = unnest(tagged_by)) %>%
    mutate(director_id = as.character(director_id),
           other_director_id = as.character(director_id)) %>%
    filter(tagged_by=="mmei") %>%
    distinct() %>%
    print(n=200)


tagging_issues %>%
    filter(proposed_resolution == "tag_bio") %>%
    mutate(tagger = unnest(tagged_by)) %>%
    filter(tagger == "mmei") %>%
    select(sheet, director_id)
tagging_issues %>%
    summarize(num_tagged = n(),
           num_wrong = sum(as.integer(!is.na(proposed_resolution))),
           num_bio_wrong = sum(as.integer(proposed_resolution=="tag_bio"))) %>%
    mutate(prop_wrong = num_wrong * 1.0/num_tagged,
           prop_bio_wrong = num_bio_wrong * 1.0/num_tagged) %>%
    arrange(desc(prop_wrong))

merged_test <-
    regex_results %>%
    inner_join(test_sample)

merged_test %>%
    filter(non_match) %>%
    count(proposed_resolution, other_dir_undisclosed)

merged_test %>%
    filter(non_match) %>% # , !is.na(other_dir_undisclosed)) %>%
    group_by(sheet) %>%
    filter(!is.na(other_dir_undisclosed)) %>%
    summarize(count=n(),
              num_incorrect=sum(as.integer(!other_dir_undisclosed)),
              num_correct=sum(as.integer(other_dir_undisclosed))) %>%
    mutate(prop_correct = 1 * num_correct / count,
           prop_incorrect = 1 * num_incorrect / count)

merged_test %>%
    filter(non_match) %>%
    summarize(count=n(),
              prop_correct=sum(other_dir_undisclosed==non_match,
                               na.rm=TRUE)/n())

merged_test %>%
    filter(non_match) %>%
    mutate(year = date_part('year', fy_end)) %>%
    group_by(year) %>%
    summarize(count=n(),
              prop_correct=sum(1*as.integer(other_dir_undisclosed==non_match))/n())

merged_test %>%
    filter(non_match) %>%
    mutate(correct = other_dir_undisclosed,
           last_sample = sheet=="test_sample #5") %>%
    lm(correct ~ last_sample, data = .) %>%
    summary()

who_tagged %>%
    mutate(tagged_by=unnest(tagged_by)) %>%
    left_join(regex_results %>%
                  filter(non_match) %>%
                  select(file_name)) %>%
    distinct() %>%
    group_by(tagged_by) %>%
    summarize(num_non_match = sum(as.integer(non_match)),
           num_filings = n()) %>%
    group_by(tagged_by) %>%
    mutate(prop_non_match = num_non_match * 1 / num_filings)

regex_results %>%
    group_by(file_name) %>%
    summarize(num_non_matches = sum(as.integer(non_match))) %>%
    inner_join(
        who_tagged %>%
            select(file_name, tagged_by) %>%
            distinct()) %>%
    inner_join(
        raw_tagging_data %>%
            filter(category=="bio") %>%
            select(uri, file_name)) %>%
    arrange(desc(num_non_matches))

rel_results <-
    directorship_results %>%
    filter(non_match, !past, !future) %>%
    inner_join(who_tagged) %>%
    select(director_id, other_director_id,
           fy_end, tagged_by) %>%
    distinct() %>%
    compute()

test_sample %>%
    inner_join(rel_results) %>%
    mutate(tag_bio = coalesce(proposed_resolution =="tag_bio", FALSE)) %>%
    # mutate(tagged_by = unnest(tagged_by)) %>%
    as.data.frame() %>%
    with(table(tagged_by, tag_bio))

rel_results %>%
    mutate(username=unnest(tagged_by)) %>%
    select(-tagged_by) %>%
    filter(username ~"^gyu") %>%
    inner_join(bio_data) %>%
    select(file_name) %>%
    distinct() %>%
    count()
