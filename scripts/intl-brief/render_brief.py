#!/usr/bin/env python3
import json
import os
from pathlib import Path
from datetime import date

brief_root = Path(os.environ.get('INTL_BRIEF_ROOT', Path(__file__).resolve().parents[2] / 'state' / 'intl-brief'))
run_date = os.environ.get('INTL_BRIEF_DATE') or date.today().isoformat()
normalized_path = brief_root / 'normalized' / f'{run_date}.json'
brief_path = brief_root / 'briefs' / f'{run_date}.md'
brief_path.parent.mkdir(parents=True, exist_ok=True)

events = json.loads(normalized_path.read_text()) if normalized_path.exists() else []

lines = ['# 国际大事简讯', '', '## 今日最重要', '']
for idx, event in enumerate(events[:8], start=1):
    lines.append(f"{idx}. **{event.get('canonical_title', '未命名事件')}**（{event.get('status_label', '待判定')}）")
    summary = event.get('summary', '').strip()
    if summary:
        lines.append(f"   - {summary}")
    lines.append('')

lines.extend(['## 分类补充', ''])
by_cat = {}
for event in events:
    by_cat.setdefault(event.get('category', '其他'), []).append(event)
for cat, items in by_cat.items():
    lines.append(f'### {cat}')
    for item in items:
        lines.append(f"- {item.get('canonical_title', '未命名事件')}（{item.get('status_label', '待判定')}）")
    lines.append('')

brief_path.write_text('\n'.join(lines).strip() + '\n')
