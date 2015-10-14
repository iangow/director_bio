def name_to_pattern(name):
    import re
    pattern = re.sub(r'\s+[\\/]([A-Z]+|DE|IN|OHIO)[\\/]', "", name)
    pattern = re.sub(r'-\s+', '-', pattern)

    # Replace special regex characters
    pattern = re.escape(pattern)

    pattern = re.sub(r'\\ ', ' ', pattern)
    pattern = re.sub(r'\\s', '\s', pattern)

    # Strip leading and trailing spaces
    pattern = re.sub(r'^\s+', "", pattern)
    pattern = re.sub(r'\s+$', "", pattern)

    # pattern = re.sub("'", "'?", pattern)

    # Make commas optional
    pattern = re.sub(r'\\,', ",?", pattern)
    pattern = re.sub(r'\.', ".?", pattern)
    pattern = re.sub(r'^THE ', "(?:THE )?", pattern)

    # pattern = re.sub(",\s+", ",?\s*", pattern)
    pattern = re.sub(r'\s+CO(MPANY)?\b', "(?: Co(?:mpany))?", pattern)
    pattern = re.sub(r'\s+&\s+', "(?: & | and )", pattern)

    pattern = re.sub(r'\bU\.?S\.?\b', 'U\.?S\.?', pattern)

    pattern = re.sub(r'\s+INC\b\.?', "(?: Inc(?:\.|orporated)?)?", pattern)
    pattern = re.sub(r'\s+(?:CORP|ORATION)\b\.?', "(?: Co(?:rp(?:oration)?))?", pattern)
    pattern = re.sub(r'\s+HOLDINGS\b', "(?: Holdings)?", pattern)

    # Allow spaces to be matched by hyphens
    pattern = re.sub(r'(?:\\-|\\ )+', "[-\\s]+", pattern)

    # Add parentheses
    pattern = '(?:' + pattern + ')'
    return pattern

def apply_regex(bio, pattern):
    import re

    def clean_bio(bio_text):

        new_text = re.sub(r'\n', " ", bio_text)
        new_text = re.sub(r'^\s*(The|THE)\s+', "", new_text)
        new_text = re.sub(r'\b-\s+\b', "-", new_text)
        new_text = re.sub(r'\s+', " ", new_text)
        new_text = re.sub(r',', '', new_text)
        return new_text

    cleaned_bio = clean_bio(bio)
    return re.findall(pattern, cleaned_bio, flags=re.I)

def names_to_pattern(names):
    patterns = [name_to_pattern(name) for name in names]
    pattern = '(' + '|'.join(patterns) + ')'
    return pattern

def names_in_bio(bio, names):

    pattern = names_to_pattern(names)

    return apply_regex(bio, pattern)
