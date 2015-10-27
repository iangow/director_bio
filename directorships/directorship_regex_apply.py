import psycopg2 as pg
import pandas as pd
from pandas.io.sql import read_sql

sql = """
    SELECT DISTINCT a.file_name, director, director_id::text, b.equilar_id, cusip,
        bio,
        as_tagged, other_director_id, other_directorship,
        other_directorship_names, other_cusip,
        directorship_present, b.uri
    FROM director_bio.bio_data AS a
    INNER JOIN director_bio.other_directorships
    USING (director_id)
    INNER JOIN director_bio.tagged_directorships AS b
    USING (director_id, other_directorship)
    WHERE directorship_present;"""

conn = pg.connect(dbname='crsp')
df = read_sql(sql, con=conn)

from directorship_regex import names_to_pattern, apply_regex

df['pattern'] = df['other_directorship_names'].map(names_to_pattern)
df['result'] =  df.apply(lambda row: apply_regex(row['as_tagged'], row['pattern']),
                            axis=1)
df['non_match'] = df['result'].map(lambda x: not x)

print(df.ix[df['non_match'],
            ['other_directorship_names', 'as_tagged', 'new_bio',
                'pattern', 'result']])
