## [ERR-20260423-001] git-fetch-github-http2

**Logged**: 2026-04-23T09:24:00+08:00
**Priority**: medium
**Status**: pending
**Area**: infra

### Summary
git fetch Hermes Agent remote failed over direct GitHub HTTP/2 transport

### Error
```
error: RPC failed; curl 16 Error in the HTTP2 framing layer
fatal: expected 'acknowledgments'
```

### Context
- Command attempted: git fetch --all --tags --prune in /opt/fnos-media/services/hermes-agent/app
- Goal: detect latest upstream before upgrade
- Environment: host network, no proxy env exported in session

### Suggested Fix
Try local proxy, or force git/curl HTTP/1.1 for GitHub fetches when HTTP/2 framing fails.

### Metadata
- Reproducible: unknown
- Related Files: /opt/fnos-media/services/hermes-agent/app

---
## [ERR-20260426-001] async-exec-session-terminated

**Logged**: 2026-04-26T05:07:00Z
**Priority**: medium
**Status**: pending
**Area**: infra

### Summary
A background exec session used for bulk agent skill assignment terminated with SIGTERM before producing usable output.

### Error
```
Exec failed (keen-sab, signal SIGTERM)
```

### Context
- Operation attempted: bulk write/verify of per-role agent skill bindings
- Session id: keen-sable / keen-sab
- Follow-up investigation showed `openclaw.json` writes were being reverted by OpenClaw config clobber protection due to invalid config state.

### Suggested Fix
Prefer official OpenClaw config patch/update paths over direct file writes when config clobber protection is active, and validate config health before attempting bulk agent skill mutations.

### Metadata
- Reproducible: unknown
- Related Files: /opt/fnos-media/services/openclaw/home/.openclaw/logs/config-audit.jsonl, /opt/fnos-media/services/openclaw/home/.openclaw/openclaw.json

---
## [ERR-20260426-001] gateway_config_patch_protected_auth

**Logged**: 2026-04-26T07:41:00Z
**Priority**: medium
**Status**: pending
**Area**: config

### Summary
Attempting to update gateway.auth via gateway config.patch failed because gateway.auth is a protected config path.

### Error
```
gateway config.patch cannot change protected config paths: gateway.auth
```

### Context
- Operation attempted: gateway.config.patch
- Target path: gateway.auth.rateLimit
- Goal: add auth rate limiting while preserving LAN/proxy access

### Suggested Fix
Use the supported full-config apply path after fetching current config and preserving existing values, or use a dedicated auth configuration flow if available.

### Metadata
- Reproducible: yes
- Related Files: /opt/fnos-media/services/openclaw/home/.openclaw/openclaw.json

---
