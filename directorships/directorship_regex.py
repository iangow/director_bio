#/usr/bin/env python3
def clean_bio(bio_text):
    import re

    new_text = re.sub(r'\n', " ", bio_text)
    new_text = re.sub(r'^\s*The\s+', "", new_text)
    new_text = re.sub(r'\b-\s+\b', "-", new_text)
    new_text = re.sub(r'\s+', " ", new_text)
    new_text = re.sub(r',', '', new_text)
    return new_text

def name_to_pattern(name):

    import re

    # Strip leading and trailing spaces
    pattern = re.sub(r'^\s+', "", name)
    pattern = re.sub(r'\s+$', "", pattern)

    # Add capturing parentheses
    pattern = '(' + pattern + ')'
    # pattern = re.sub("'", "'?", pattern)

    # Make commas optional
    pattern = re.sub(r',', ",?", pattern)

    # pattern = re.sub(",\s+", ",?\s*", pattern)
    pattern = re.sub(r'\s+CO(MPANY)?\b', "(?: Co(?:mpany))?", pattern)
    pattern = re.sub(r'\s+&\s+', "(?: & | and )", pattern)
    pattern = re.sub(r'\s+[\\/]([A-Z]+|DE|IN|OHIO)[\\/]', "", pattern)
    pattern = re.sub(r'\bU\.?S\.?\b', 'U\.?S\.?', pattern)

    pattern = re.sub(r'\s+INC\.?\b', "(?: Inc(?:\.|orporated)?)?", pattern)
    pattern = re.sub(r'\s+CORP\b\.?', "(?: Co(?:oration)?)?", pattern)
    pattern = re.sub(r'\s+HOLDINGS\b', "(?: Holdings)?", pattern)

    # Allow spaces to be matched by hyphens
    pattern = re.sub(r'\s', "[-\s]", pattern)
    return pattern

import pandas as pd

df = pd.read_pickle('directorships/directorships')

df['new_bio'] = df['as_tagged'].map(clean_bio)

df['pattern'] = df['other_directorship'].map(name_to_pattern)

# print(df[:10])

def apply_regex(bio, pattern):
    import re

    cleaned_bio = clean_bio(bio)
    return re.findall(pattern, cleaned_bio, flags=re.I)

df['result'] =  df.apply(lambda row: apply_regex(row['as_tagged'], row['pattern']),
                            axis=1)

df['non_match'] = df['result'].map(lambda x: not x)
pd.set_option('display.width', 1000)
print(df.ix[df['non_match'],
            ['other_directorship', 'as_tagged', 'new_bio',
                'pattern', 'result']])
