import psycopg2 as pg
import pandas as pd
from pandas.io.sql import read_sql

sql = """
    SELECT DISTINCT a.file_name, director, a.director_id::text, c.equilar_id, cusip,
        bio,
        as_tagged, other_director_id, other_directorship,
        other_directorship_names AS other_names,
        -- array_cat(other_directorship_names, tagged_names) AS other_names,
        other_cusip,
        directorship_present, c.uri
    FROM director_bio.bio_data AS a
    INNER JOIN director_bio.other_directorships AS b
    USING (director_id)
    LEFT JOIN director_bio.tagged_names
    USING (other_equilar_id)
    INNER JOIN director_bio.tagged_directorships AS c
    ON b.director_id=c.director_id AND c.other_directorship=ANY(b.other_directorships)
    WHERE directorship_present;"""

conn = pg.connect(dbname='crsp')
df = read_sql(sql, con=conn)

from directorship_regex import names_to_pattern, apply_regex

df['pattern'] = df['other_names'].map(names_to_pattern)
df['result'] =  df.apply(lambda row: apply_regex(row['as_tagged'], row['pattern']),
                            axis=1)
df['non_match'] = df['result'].map(lambda x: not x)

print(df.ix[df['non_match'],
            ['other_names', 'as_tagged', 'new_bio',
                'pattern', 'result']])
