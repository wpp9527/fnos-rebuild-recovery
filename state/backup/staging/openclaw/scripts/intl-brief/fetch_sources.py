#!/usr/bin/env python3
import json
import os
import urllib.request
import xml.etree.ElementTree as ET
from urllib.error import URLError
from pathlib import Path
from datetime import date

brief_root = Path(os.environ.get('INTL_BRIEF_ROOT', Path(__file__).resolve().parents[2] / 'state' / 'intl-brief'))
run_date = os.environ.get('INTL_BRIEF_DATE') or date.today().isoformat()
raw_path = brief_root / 'raw' / f'{run_date}.json'
raw_path.parent.mkdir(parents=True, exist_ok=True)

feeds_env = os.environ.get('INTL_BRIEF_FEEDS', '中新网国际=https://www.chinanews.com.cn/rss/world.xml').strip()
if raw_path.exists() and not feeds_env:
    raise SystemExit(0)

items = []
errors = []
if feeds_env:
    for part in feeds_env.split(','):
        if '=' not in part:
            continue
        source, url = part.split('=', 1)
        source = source.strip() or 'Feed'
        url = url.strip()
        if not url:
            continue
        try:
            with urllib.request.urlopen(url, timeout=8) as resp:
                xml_bytes = resp.read()
            root = ET.fromstring(xml_bytes)
            for item in root.findall('.//item'):
                title = (item.findtext('title') or '').strip()
                link = (item.findtext('link') or '').strip()
                summary = (item.findtext('description') or '').strip()
                published_at = (item.findtext('pubDate') or f'{run_date}T00:00:00Z').strip()
                items.append({
                    'source': source,
                    'title': title,
                    'url': link,
                    'summary': summary,
                    'published_at': published_at,
                })
        except Exception as exc:
            errors.append({'source': source, 'url': url, 'error': repr(exc)})

if not items and raw_path.exists():
    raise SystemExit(0)

if not items and not raw_path.exists():
    items = [
        {
            'source': 'bootstrap',
            'title': 'Fed signals higher-for-longer rates as markets reprice',
            'summary': 'Bootstrap sample used before real public sources are connected.',
            'published_at': f'{run_date}T00:00:00Z'
        }
    ]

if items:
    raw_path.write_text(json.dumps(items, ensure_ascii=False, indent=2) + '\n')
