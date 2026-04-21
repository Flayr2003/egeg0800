import ast
import json
import os
import re
from pathlib import Path

from openai import OpenAI

ROOT = Path('/home/ubuntu/egeg0800_work')
KEYS_FILE = ROOT / 'lib/languages/languages_keys.dart'
OUT_FILE = ROOT / 'lib/languages/local_fallback_translations.dart'
MODEL = 'gpt-4.1-mini'
BATCH_SIZE = 70


def parse_dart_string_expression(expr: str) -> str:
    parts = re.findall(r"'(?:[^'\\]|\\.)*'|\"(?:[^\"\\]|\\.)*\"", expr, re.DOTALL)
    return ''.join(ast.literal_eval(part) for part in parts)


def extract_keys(text: str):
    pattern = re.compile(r'static const String\s+(\w+)\s*=\s*(.*?);', re.DOTALL)
    items = []
    for name, expr in pattern.findall(text):
        value = parse_dart_string_expression(expr)
        items.append((name, value))
    return items


def chunked(items, size):
    for i in range(0, len(items), size):
        yield items[i:i + size]


def translate_batch(client: OpenAI, batch):
    phrases = [value for _, value in batch]
    system = (
        'You translate mobile app UI strings from English to Arabic. '
        'Preserve placeholders such as @name, %s, {count}, newline breaks, punctuation intent, '
        'and product words like PLUS+ when appropriate. Return only valid JSON mapping the original '
        'English string to its Arabic translation. Do not omit any item.'
    )
    user = json.dumps(phrases, ensure_ascii=False)
    response = client.chat.completions.create(
        model=MODEL,
        temperature=0.2,
        messages=[
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': user},
        ],
        response_format={'type': 'json_object'},
    )
    text = response.choices[0].message.content.strip()
    data = json.loads(text)
    missing = [p for p in phrases if p not in data]
    if missing:
        raise ValueError(f'Missing translations for: {missing[:10]}')
    return data


def dart_escape(value: str) -> str:
    return value.replace('\\', '\\\\').replace('\n', '\\n').replace("'", "\\'")


def write_dart_file(keys, ar_map):
    en_lines = []
    ar_lines = []
    seen_keys = set()
    for _, value in keys:
        if value in seen_keys:
            continue
        seen_keys.add(value)
        escaped_key = dart_escape(value)
        escaped_ar = dart_escape(ar_map[value])
        en_lines.append(f"    '{escaped_key}': '{escaped_key}',")
        ar_lines.append(f"    '{escaped_key}': '{escaped_ar}',")

    content = f"""class LocalFallbackTranslations {{
  static const Map<String, Map<String, String>> values = {{
    'en': {{
{os.linesep.join(en_lines)}
    }},
    'ar': {{
{os.linesep.join(ar_lines)}
    }},
  }};
}}
"""
    OUT_FILE.write_text(content, encoding='utf-8')


def main():
    text = KEYS_FILE.read_text(encoding='utf-8')
    keys = extract_keys(text)
    if not keys:
        raise SystemExit('No language keys found')

    client = OpenAI()
    ar_map = {}
    for batch in chunked(keys, BATCH_SIZE):
        ar_map.update(translate_batch(client, batch))

    write_dart_file(keys, ar_map)
    print(f'Generated {len(keys)} keys at {OUT_FILE}')


if __name__ == '__main__':
    main()
