import json
import os
import subprocess
import sys
from typing import Any

try:
    import requests
    from requests import Response
except Exception:
    requests = None
    Response = None

_SCRIPT = '/truth-fastpath/scripts/runtime_truth_reply.py'
_PREFIX = '[FASTPATH]'
_KEYS = [
    '模型', '分配', '主模型', 'fallback', 'provider', 'providers',
    'model', 'models', 'inventory', '主链', '备用链', '配备',
    '太子', '角色', '中书省', '门下省', '尚书省', '户部', '工部'
]
_ENABLED = os.environ.get('OPENCLAW_TRUTH_FASTPATH', '1') == '1'
_DEBUG = os.environ.get('OPENCLAW_TRUTH_FASTPATH_DEBUG', '1') == '1'


def _log(msg: str) -> None:
    if _DEBUG:
        print(f'{_PREFIX} {msg}', file=sys.stderr, flush=True)


def _extract_text(kwargs: dict) -> str:
    payload = kwargs.get('json')
    if not isinstance(payload, dict):
        data = kwargs.get('data')
        if isinstance(data, (bytes, bytearray)):
            try:
                payload = json.loads(data.decode('utf-8', errors='ignore'))
            except Exception:
                payload = None
        elif isinstance(data, str):
            try:
                payload = json.loads(data)
            except Exception:
                payload = None
    if not isinstance(payload, dict):
        return ''
    msgs = payload.get('messages') or []
    parts = []
    if isinstance(msgs, list):
        for m in msgs:
            if not isinstance(m, dict):
                continue
            content = m.get('content')
            if isinstance(content, str):
                parts.append(content)
            elif isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and isinstance(item.get('text'), str):
                        parts.append(item['text'])
    return ' '.join(parts).strip()


def _hit(q: str) -> bool:
    q2 = (q or '').lower()
    return any(k.lower() in q2 for k in _KEYS)


def _truth_reply(q: str) -> str:
    if not os.path.exists(_SCRIPT):
        raise RuntimeError(f'missing script: {_SCRIPT}')
    proc = subprocess.run(
        [sys.executable, _SCRIPT, q],
        check=False,
        capture_output=True,
        text=True,
        timeout=5,
    )
    out = (proc.stdout or '').strip()
    err = (proc.stderr or '').strip()
    if proc.returncode == 0 and out:
        return out
    if out == 'NO_HIT':
        raise LookupError('no hit')
    raise RuntimeError(err or out or f'runtime_truth_reply.py rc={proc.returncode}')


def _fake_response(text: str, model: str = 'truth-fastpath/local'):
    resp = Response()
    resp.status_code = 200
    resp.headers['Content-Type'] = 'application/json'
    body = {
        'id': 'chatcmpl-truth-fastpath',
        'object': 'chat.completion',
        'created': 0,
        'model': model,
        'choices': [
            {
                'index': 0,
                'message': {'role': 'assistant', 'content': text},
                'finish_reason': 'stop',
            }
        ],
        'usage': {'prompt_tokens': 0, 'completion_tokens': 0, 'total_tokens': 0},
    }
    resp._content = json.dumps(body, ensure_ascii=False).encode('utf-8')
    resp.encoding = 'utf-8'
    return resp


def _patch_requests() -> None:
    if not requests or not Response:
        return
    orig = requests.sessions.Session.request

    def wrapped(self, method: str, url: str, *args: Any, **kwargs: Any):
        try:
            if _ENABLED and method and method.upper() == 'POST' and '/chat/completions' in (url or ''):
                q = _extract_text(kwargs)
                if q and _hit(q):
                    reply = _truth_reply(q)
                    _log(f'FASTPATH_HIT q={q[:120]!r}')
                    return _fake_response(reply)
                if q:
                    _log(f'FASTPATH_MISS q={q[:120]!r}')
        except LookupError:
            q = _extract_text(kwargs)
            if q:
                _log(f'FASTPATH_MISS q={q[:120]!r}')
        except Exception as e:
            q = _extract_text(kwargs)
            _log(f'FASTPATH_ERROR q={q[:120]!r} err={e}')
            return _fake_response('当前 truth-first 读取失败，请稍后重试。')
        return orig(self, method, url, *args, **kwargs)

    requests.sessions.Session.request = wrapped
    _log('requests patch installed')


_patch_requests()
