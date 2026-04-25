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
