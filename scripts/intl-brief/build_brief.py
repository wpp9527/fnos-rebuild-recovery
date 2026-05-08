#!/usr/bin/env python3
import json
import os
import re
from pathlib import Path
from datetime import date

brief_root = Path(os.environ.get('INTL_BRIEF_ROOT', Path(__file__).resolve().parents[2] / 'state' / 'intl-brief'))
run_date = os.environ.get('INTL_BRIEF_DATE') or date.today().isoformat()
raw_path = brief_root / 'raw' / f'{run_date}.json'
out_path = brief_root / 'normalized' / f'{run_date}.json'
out_path.parent.mkdir(parents=True, exist_ok=True)

items = json.loads(raw_path.read_text()) if raw_path.exists() else []

def classify(title: str, summary: str = '') -> str:
    t = (title + ' ' + summary)
    if any(k in t for k in ['石油','原油','油价','市场','经济','贸易','关税','通胀','通膨','股市','债市','货币','央行','GDP','出口','进口','金融','投资','预算','利率','fed','market','rate','bond','stocks','tariff','inflation','oil']):
        return '全球经济与市场'
    if any(k in t for k in ['地震','火山','台风','洪水','火灾','坠毁','爆炸','空难','海啸','暴雨','干旱','疫情','传染病']):
        return '灾害与环境'
    if any(k in t for k in ['导弹','军事','国防军','军队','航母','军机','战机','海军','空军','核武器','核武','舰队','国防部','五角大楼','武装力量','战争','阵亡','military','missile','drone','attack','defense','navy','ceasefire']):
        return '军事与安全'
    if any(k in t for k in ['AI','人工智能','芯片','半导体','科技','手机','数据','量子','机器人','算法','5G','6G','模型','大模型','软件','操作系统','ai','chatgpt','openai','nvidia','tech','semiconductor']):
        return '科技与AI'
    if any(k in t for k in ['中国','国台办','外交部','中方','台湾','台独','北京回应','新华社','国务院','习近平']):
        return '中国相关外部动态'
    return '国际政治'

def dedup_key(title: str) -> str:
    t = title.lower()
    if 'fed' in t and ('market' in t or 'markets' in t or 'rate' in t or 'rates' in t):
        return 'fed-markets'
    if 'ceasefire' in t and ('middle east' in t or 'talks' in t):
        return 'middle-east-ceasefire'
    return re.sub(r'[^a-z0-9一-鿿]+', '-', t).strip('-')[:80]

def summary_matches_title(title: str, summary: str) -> bool:
    title_tokens = [tok for tok in re.findall(r'[\u4e00-\u9fff]{2,}|[A-Za-z]{3,}|\d+(?:\.\d+)?', title) if tok]
    if not title_tokens:
        return True
    return any(tok.lower() in summary.lower() for tok in title_tokens[:6] if len(tok) >= 2)

merged = {}
for item in items:
    title = item.get('title', '')
    summary = item.get('summary', '')
    if summary and not summary_matches_title(title, summary):
        summary = ''
    key = dedup_key(title)
    entry = merged.setdefault(key, {
        'event_id': key,
        'canonical_title': title,
        'category': classify(title, summary),
        'summary': summary,
        'source_count': 0,
        'sources': [],
        'status_label': '多源基本一致',
    })
    entry['source_count'] += 1
    src = item.get('source')
    if src and src not in entry['sources']:
        entry['sources'].append(src)
    if len(summary) > len(entry.get('summary', '')):
        entry['summary'] = summary

normalized = list(merged.values())
out_path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2) + '\n')
