# Cleanup Report — Round 2 (2026-04-21)

## Removed
- broken symlink: `/opt/fnos-media/services/openclaw/home/.openclaw/workspace-main/scripts/linucb_router.py`
  - target: `/Users/bingsen/clawd/openclaw-sansheng-liubu/scripts/linucb_router.py`
- broken symlink: `/opt/fnos-media/services/openclaw/home/.openclaw/workspace-main/scripts/agentrec_advisor.py`
  - target: `/Users/bingsen/clawd/openclaw-sansheng-liubu/scripts/agentrec_advisor.py`
- empty dir: `/opt/fnos-media/services/openclaw/home/.openclaw/workspace/state`

## Kept intentionally
- none

## Not touched in this round
- backups under `.openclaw/backups/`
- runtime cache/session dirs under `clawpanel/`, `qqbot/`, etc.
- role bootstrap files under `.openclaw/agents/*`