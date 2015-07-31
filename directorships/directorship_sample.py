import psycopg2 as pg
import pandas as pd
from pandas.io.sql import read_sql

sql = """
    SELECT file_name, director, director_id::text, quote AS bio, 
        as_tagged, other_director_id, other_directorship, 
        directorship_present, b.uri
    FROM director_bio.bio_data AS a
    INNER JOIN director_bio.tagged_directorships AS b
    USING (director_id, file_name)
    WHERE directorship_present
    LIMIT 1000;"""

conn = pg.connect(dbname='crsp', host='iangow.me')
df = read_sql(sql, con=conn)

# print(df)

df.to_pickle('directorships')

