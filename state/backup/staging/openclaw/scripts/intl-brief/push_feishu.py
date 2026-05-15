#!/usr/bin/env python3
import json
import os
import urllib.request
from pathlib import Path
from datetime import date

brief_root = Path(os.environ.get('INTL_BRIEF_ROOT', Path(__file__).resolve().parents[2] / 'state' / 'intl-brief'))
run_date = os.environ.get('INTL_BRIEF_DATE') or date.today().isoformat()
norm_path = brief_root / 'normalized' / f'{run_date}.json'
status_path = brief_root / 'runs' / 'latest.json'
env_path = Path('/mnt/nas/backup/fnos/latest/services/docker-stack/channels/feishu/.env')

env = {}
if env_path.exists():
    for line in env_path.read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        k, v = line.split('=', 1)
        env[k] = v

payload = json.loads(norm_path.read_text()) if norm_path.exists() else {'events': []}
events = payload if isinstance(payload, list) else payload.get("events", [])

# dedup: skip push if normalized content has not changed
import hashlib
content_hash = hashlib.md5(json.dumps(events, sort_keys=True).encode()).hexdigest()
existing_status = json.loads(status_path.read_text()) if status_path.exists() and status_path.stat().st_size > 30 else {}
if existing_status.get("delivery_hash") == content_hash:
    status_path.write_text(json.dumps({**existing_status}, ensure_ascii=False, indent=2) + chr(10))
    raise SystemExit(0)
by_cat = {}
for e in events:
    by_cat.setdefault(e.get('category', '其他'), []).append(e)

app_id = env.get('FEISHU_APP_ID', '')
app_secret = env.get('FEISHU_APP_SECRET', '')
target_open_id = env.get('TARGET_OPEN_ID', '')

def push_text(text_bytes):
    if not (app_id and app_secret and target_open_id):
        return None
    r = urllib.request.Request(
        'https://open.larksuite.com/open-apis/auth/v3/tenant_access_token/internal',
        data=json.dumps({'app_id': app_id, 'app_secret': app_secret}).encode(),
        headers={'Content-Type': 'application/json; charset=utf-8'},
    )
    with urllib.request.urlopen(r, timeout=20) as resp:
        token = json.loads(resp.read())['tenant_access_token']
    text = text_bytes[:2800]
    body = json.dumps({
        'receive_id': target_open_id,
        'msg_type': 'text',
        'content': json.dumps({'text': text}, ensure_ascii=False)
    }).encode()
    r2 = urllib.request.Request(
        'https://open.larksuite.com/open-apis/im/v1/messages?receive_id_type=open_id',
        data=body,
        headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json; charset=utf-8'},
    )
    with urllib.request.urlopen(r2, timeout=20) as resp:
        return json.loads(resp.read())

cat_emoji = {
    '全球经济与市场': '\U0001f4c8',
    '灾害与环境': '\u26a1',
    '军事与安全': '\U0001f6e1\ufe0f',
    '科技与AI': '\U0001f916',
    '中国相关外部动态': '\U0001f30d',
    '国际政治': '\U0001f30f',
    '其他': '\U0001f4dd',
}
cat_key = {
    '全球经济与市场': 'global_market',
    '灾害与环境': 'disaster',
    '军事与安全': 'military',
    '科技与AI': 'tech_ai',
    '中国相关外部动态': 'china_related',
    '国际政治': 'politics',
    '其他': 'other',
}
numeric = {1: '1\ufe0f\u20e3', 2: '2\ufe0f\u20e3', 3: '3\ufe0f\u20e3', 4: '4\ufe0f\u20e3', 5: '5\ufe0f\u20e3'}

delivery_log = {}

# top 5 summary push
top5 = events[:5]
top5_titles = {e.get('canonical_title', '') for e in top5} if top5 else set()
if top5:
    lines = [f'\U0001f310 \u56fd\u9645\u5927\u4e8b\u7b80\u8baf \u2022 {run_date}', '', '\u2606 \u4eca\u65e5\u6700\u91cd\u8981', '']
    for idx, e in enumerate(top5, 1):
        num = numeric.get(idx, f'{idx}.')
        lines.append(f'{num} {e.get("canonical_title", "")}\uff08{e.get("status_label", "")}\uff09')
        s = e.get('summary', '').strip()[:120]
        if s:
            lines.append(f'   {s}')
            lines.append('')
    result = push_text('\n'.join(lines).strip())
    delivery_log['top5'] = {'ok': result is not None, 'items': len(top5)}

# per-category pushes
for cat in ['全球经济与市场', '灾害与环境', '军事与安全', '科技与AI', '中国相关外部动态', '国际政治']:
    items = [e for e in by_cat.get(cat, []) if e.get('canonical_title', '') not in top5_titles][:4]
    if not items:
        continue
    emoji = cat_emoji.get(cat, '\U0001f4dd')
    key = cat_key.get(cat, cat)
    lines = [f'{emoji} {cat}', '']
    for e in items:
        lines.append(f'\u2022 {e.get("canonical_title", "")}\uff08{e.get("status_label", "")}\uff09')
        s = e.get('summary', '').strip()[:100]
        if s:
            lines.append(f'  {s}')
            lines.append('')
    result = push_text('\n'.join(lines).strip())
    delivery_log[key] = {'ok': result is not None, 'items': len(items)}

status = {'status': 'ok', 'date': run_date, 'delivery': delivery_log}
existing = json.loads(status_path.read_text()) if status_path.exists() and status_path.stat().st_size > 10 else {}
status = {**existing, "status": "ok", "delivery": delivery_log}
status_path.write_text(json.dumps({**status, "delivery_hash": content_hash}, ensure_ascii=False, indent=2) + chr(10))
