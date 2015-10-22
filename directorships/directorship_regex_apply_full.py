from directorship_regex import names_in_bio
import sqlalchemy as sa
import pandas as pd

import psycopg2 as pg
import pandas as pd
from pandas.io.sql import read_sql

from sqlalchemy import create_engine
engine = create_engine('postgresql://iangow.me/crsp')

sql = """
    SELECT a.file_name, c.date_filed, director, a.equilar_id, a.fy_end,
        director_id, cusip,
        bio,
        start_date, end_date,
        other_director_id, other_directorship, other_cusip,
        other_start_date,
        other_end_date,
        other_directorship_names
    FROM director_bio.bio_data AS a
    INNER JOIN director_bio.other_directorships
    USING (director_id)
    INNER JOIN filings.filings AS c
    USING (file_name)"""

df = pd.read_sql(sa.text(sql), engine)

df['result'] =  df.apply(lambda row: names_in_bio(row['bio'],
                                                  row['other_directorship_names']),
                            axis=1)
df['non_match'] = df['result'].map(lambda x: not x)

# Push data to PostgreSQL database
df.to_sql('directorship_results', engine, schema="director_bio",
         if_exists="replace", index=False)

engine.execute("ALTER TABLE director_bio.directorship_results OWNER TO director_bio_team")
