import psycopg2 as pg
import pandas as pd
from pandas.io.sql import read_sql

sql = """
    SELECT a.file_name, director, director_id::text, bio,
        -- as_tagged,
         other_director_id, other_directorship,
        other_directorship_names --, directorship_present, b.uri
    FROM director_bio.bio_data AS a
    INNER JOIN director_bio.other_directorships
    USING (director_id)"""

conn = pg.connect(dbname='crsp')
df = read_sql(sql, con=conn)

# print(df)

df.to_pickle('directorships/directorships_full')

