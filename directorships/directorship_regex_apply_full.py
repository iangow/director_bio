#!/usr/bin/env python3
import pandas as pd

# Get data from database
import sqlalchemy as sa
import psycopg2 as pg
from pandas.io.sql import read_sql

from sqlalchemy import create_engine
engine = create_engine('postgresql://iangow.me/crsp')

sql = """
    SELECT DISTINCT director_id::text, fy_end, a.file_name, a.bio,
        b.other_director_id::text,
        array_cat(other_directorship_names, tagged_names) AS other_names
    FROM director_bio.bio_data AS a
    INNER JOIN director_bio.other_directorships AS b
    USING (director_id, fy_end)
    LEFT JOIN director_bio.tagged_names
    USING (other_equilar_id)
    """

df = pd.read_sql(sa.text(sql), engine)

# df.to_pickle('directorships.pickle')
# df = pd.read_pickle('directorships.pickle')

# Apply regular expression code to bios and names
from directorship_regex import names_in_bio
df['result'] = df.apply(lambda row: names_in_bio(row['bio'],
                                                 row['other_names']),
                        axis=1)
df['non_match'] = df['result'].map(lambda x: not x)

# Delete columns not needed any more
del df['bio']
del df['other_names']

# Push data to PostgreSQL database
df.to_sql('regex_results', engine, schema="director_bio",
         if_exists="replace", index=False)

# Do some database-related clean-up
engine.execute(
    """
    ALTER TABLE director_bio.regex_results
    OWNER TO director_bio_team;
    
    ALTER TABLE director_bio.regex_results
        ALTER COLUMN director_id TYPE equilar_director_id
        USING director_id::equilar_director_id;

    ALTER TABLE director_bio.regex_results
        ALTER COLUMN other_director_id TYPE equilar_director_id
        USING other_director_id::equilar_director_id;

    CREATE INDEX ON director_bio.regex_results
        (file_name, director_id, other_director_id)
    """)
