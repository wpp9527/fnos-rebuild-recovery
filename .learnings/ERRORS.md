# Errors

Command failures and integration errors.

---

## 2026-05-22 - Cron MDC scrape killed by tool timeout

- Context: Cron requested running `/vol1/1000/docker/mdc/auto-mdc.sh` and reporting tail/results.
- What happened: The command exceeded the 600s exec timeout and was SIGTERM'd around 14:12. MDC had processed 19/44 items (~43.1%) at the log tail.
- Note: A follow-up diagnostic command used `/bin/sh` with `set -o pipefail`, which failed because dash does not support it; use `bash -lc` when relying on pipefail.
