# -*- coding: UTF-8 -*-
def name_to_pattern(name):
    """This function takes a name and converts it to a regular expression
    pattern for matching.
    """

    import re

    # Remove state abbreviations
    pattern = re.sub(r'\s+[\\/]([A-Z]+|DE|IN|OHIO)[\\/]', "", name)
    pattern = re.sub(r'[A-Z]{2}$', "", pattern)

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

    # Address curly apostrophes
    pattern = re.sub(u"’", "'", pattern)

    # US matches U.S. and vice versa
    pattern = re.sub(r'\bU\.?S\.?\b', 'U\.?S\.?', pattern)

    # Variants on incorporated, corporation, etc., which are often omitted
    pattern = re.sub(r'\s+INC\b\.?', "(?: Inc(?:\.|orporated)?)?", pattern)
    pattern = re.sub(r'\s+(?:CORP|ORATION)\b\.?', "(?: Co(?:rp(?:oration)?))?", pattern)
    pattern = re.sub(r'\s+HOLDINGS\b', "(?: Holdings)?", pattern)
    pattern = re.sub(r'\s+GROUP\b', "(?: Group)?", pattern)
    pattern = re.sub(r'\s+LTD\b', "(?: Ltd)?", pattern)

    # Allow spaces to be matched by hyphens
    pattern = re.sub(r'-\s+', '-', pattern)
    pattern = re.sub(r'[\-\s]+', "[\-\s]+", pattern)

    # Allow "and" to be matched by "&" and vice versa
    pattern = re.sub(r'(?:and|&)', '(?:and|&)', pattern)

    # Add parentheses
    pattern = '(?:' + pattern + ')'
    return pattern

def apply_regex(bio, pattern):
    """This function takes a bio and a regular expression pattern and returns
    the matches, if any.
    """

    import re

    def clean_bio(bio_text):

        # Remove non-breaking spaces from names
        new_text = bio_text.replace(u'\xa0', u' ')

        # Convert curly apostrophes
        new_text = re.sub(u"’", "'", new_text)

        new_text = re.sub(r'\n', " ", new_text)
        new_text = re.sub(r'^\s*(The|THE)\s+', "", new_text)
        new_text = re.sub(r'\b-\s+\b', "-", new_text)
        new_text = re.sub(r'\s+', " ", new_text)
        new_text = re.sub(r',', '', new_text)
        return new_text

    cleaned_bio = clean_bio(bio)
    return re.findall(pattern, cleaned_bio, flags=re.I)

def names_to_pattern(names):
    """This function takes a list of names and returns a regular expression
    pattern that can be used to match them in text
    """
    # Remove non-breaking spaces from names
    names = [name.replace(u'\xa0', u' ') for name in names]

    # Only check distinct names
    names = list(set(names))

    patterns = [name_to_pattern(name) for name in names]
    pattern = '(' + '|'.join(patterns) + ')'
    return pattern

def names_in_bio(bio, names):
    """This simple function checks for matches in a bio from a list of names."""
    pattern = names_to_pattern(names)

    return apply_regex(bio, pattern)
