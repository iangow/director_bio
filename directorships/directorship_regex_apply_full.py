from directorship_regex import names_in_bio

import pandas as pd

df = pd.read_pickle('directorships/directorships_full')

# df['pattern'] = df['other_directorship_names'].map(names_to_pattern)
df['result'] =  df.apply(lambda row: names_in_bio(row['bio'], row['other_directorship_names']),
                            axis=1)
df['non_match'] = df['result'].map(lambda x: not x)

print(df.ix[df['non_match'],
            ['other_directorship_names', 'non_match',
                'pattern', 'result']])

from sqlalchemy import create_engine
engine = create_engine('postgresql://iangow.me:5432/crsp')
df.to_sql('directorship_results', engine, schema="director_bio"
