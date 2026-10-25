import json
import re

def load_catalog(path, words):
    data = json.loads(path.read_text(encoding='utf-8'))
    chapters = data['chapters']
    ids = set(); codes = set()
    for chapter in chapters:
        key = chapter['chapter_id']
        if not re.fullmatch(r'chapter-\d{2}', key) or key in ids:
            raise ValueError('Duplicate/invalid chapter id')
        ids.add(key)
        if not chapter['words']: raise ValueError('Empty chapter')
        for word in chapter['words']:
            word_id = word['word_id']
            if not re.fullmatch(r'WORD\d{4}', word_id): raise ValueError('Invalid word id')
            code = word_id[4:]
            if code in codes or words.get(code) != word['label']:
                raise ValueError('Curriculum and model labels differ')
            codes.add(code)
    if codes != set(words): raise ValueError('Incomplete curriculum')
    return data
