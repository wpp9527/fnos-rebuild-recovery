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
## [ERR-20260510-001] exec_shell_pipefail

**Logged**: 2026-05-10T02:05:00+08:00
**Priority**: low
**Status**: pending
**Area**: infra

### Summary
Default exec shell rejected `set -o pipefail` because `/usr/bin/sh` does not support it.

### Details
A cron task wrapper initially used `set -o pipefail` directly and failed with `/usr/bin/sh: 1: set: Illegal option -o pipefail`. Retried successfully by invoking `bash -lc` explicitly.

### Suggested Action
Use `bash -lc` whenever relying on Bash-only features such as `pipefail` or `PIPESTATUS`.

### Metadata
- Source: error
- Tags: shell, exec, bash

---

## [ERR-20260510-001] shell_pipefail_with_sh

**Logged**: 2026-05-10T04:01:00+08:00
**Priority**: low
**Status**: pending
**Area**: infra

### Summary
Used `set -o pipefail` under `/usr/bin/sh`, which failed because this shell does not support that option.

### Details
When collecting cron script logs, an exec command began with `set -o pipefail` without forcing bash. On this host the default shell was `/usr/bin/sh`, causing `Illegal option -o pipefail`.

### Suggested Action
Use `bash -lc 'set -o pipefail; ...'` when pipefail is needed, or omit pipefail for simple log collection commands.

### Metadata
- Source: error
- Tags: shell, openclaw-exec, cron

---

## 2026-05-11 - POSIX sh printf leading dashes

- **Context**: While locating Hermes installation, command used `printf '--- heading ---\n'` under `/usr/bin/sh`.
- **Error**: `printf: Illegal option --` because some POSIX `printf` implementations parse a leading `--`-like format oddly unless guarded.
- **Fix**: Use `printf '%s\n' '--- heading ---'` or `echo` for headings in portable shell snippets.

## 2026-05-11 - web_search provider does not support country filter

- **Context**: Searching for Hermes Agent upstream with `web_search` while passing `country=US`.
- **Error**: Gemini provider returned `unsupported_country`.
- **Fix**: Omit unsupported filters unless the configured provider is Brave/Perplexity.

## 2026-05-11 - web_search configured provider missing base URL

- **Context**: Retried Hermes upstream search without country filters.
- **Error**: `SearXNG base URL is not configured`.
- **Fix**: Use `web_fetch` on known URLs, local docs/source, or ask for upstream repo when search backend is unavailable.

## 2026-05-11 - GitHub skill path unavailable

- **Context**: User provided GitHub repo `NousResearch/hermes-agent`; assistant tried to read `~/skills/github/SKILL.md` from available skills list.
- **Error**: File path did not exist in this runtime.
- **Fix**: Fall back to direct local `git`/filesystem inspection and `web_fetch`/GitHub API if available; do not block on missing skill file.

## 2026-05-17 — Shell printf gotcha with leading dashes

- **Context:** While verifying MDC auto-scrape results, ran a shell snippet with `printf '--- auto-mdc.sh ---\n'` under `/usr/bin/sh`.
- **Error:** `/usr/bin/sh: printf: Illegal option --`
- **Cause:** Some shell `printf` builtins interpret a format string beginning with `-` as an option unless guarded.
- **Fix:** Use `printf '%s\n' '--- label ---'` or `printf -- '--- label ---\n'` in portable snippets.

## 2026-05-17 - exec shell pipefail gotcha

- **Context:** While checking MDC logs after a cron run, used `set -o pipefail` in `exec` without forcing bash.
- **Error:** `/usr/bin/sh: 1: set: Illegal option -o pipefail` because the tool command ran under `/bin/sh`.
- **Fix:** Use `bash -lc 'set -o pipefail; ...'` when relying on bash options, or avoid pipefail for simple log inspection.
## [ERR-20260521-001] exec_shell_pipefail

**Logged**: 2026-05-21T16:01:00+08:00
**Priority**: low
**Status**: pending
**Area**: infra

### Summary
OpenClaw exec default shell may be `/usr/bin/sh`, where `set -o pipefail` is invalid.

### Details
A cron task wrapper used `set -o pipefail` without invoking bash and failed before running the target script.

### Suggested Action
When pipefail or PIPESTATUS is needed, execute the command through `bash -lc`.

### Metadata
- Source: error
- Tags: openclaw, shell, cron

---
## [ERR-20260522-001] shell_pipefail_in_sh

**Logged**: 2026-05-22T01:29:00+08:00
**Priority**: low
**Status**: pending
**Area**: infra

### Summary
Used `set -o pipefail` under `/usr/bin/sh`, which failed because this shell does not support that option.

### Details
For shell commands needing `pipefail`, wrap with `bash -lc` instead of relying on `/bin/sh`.

### Suggested Action
Use `bash -lc set
