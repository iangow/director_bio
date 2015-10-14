from directorship_regex import clean_bio, names_to_pattern, apply_regex

import pandas as pd

df = pd.read_pickle('directorships/directorships')

df['new_bio'] = df['as_tagged'].map(clean_bio)
df['pattern'] = df['other_directorship_names'].map(names_to_pattern)
df['result'] =  df.apply(lambda row: apply_regex(row['as_tagged'], row['pattern']),
                            axis=1)
df['non_match'] = df['result'].map(lambda x: not x)

print(df.ix[df['non_match'],
            ['other_directorship_names', 'as_tagged', 'new_bio',
                'pattern', 'result']])
