#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
mkdir -p "$RESTORE_STATE_ROOT"

HOST_OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" bash "$ROOT/restore/checks/check-host-prereqs.sh")"
GITHUB_OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" bash "$ROOT/restore/checks/check-github-access.sh")"
NAS_OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" bash "$ROOT/restore/checks/check-nas-access.sh")"
SECRETS_OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" bash "$ROOT/restore/checks/check-secrets.sh")"

printf '%s' "$HOST_OUT" | grep -Fq 'PASS' || { echo 'host prereqs did not report PASS' >&2; exit 1; }
printf '%s' "$GITHUB_OUT" | grep -Eq 'PASS|WARN' || { echo 'github check did not report PASS/WARN' >&2; exit 1; }
printf '%s' "$NAS_OUT" | grep -Eq 'PASS|WARN' || { echo 'nas check did not report PASS/WARN' >&2; exit 1; }
printf '%s' "$SECRETS_OUT" | grep -Eq 'PASS|WARN' || { echo 'secrets check did not report PASS/WARN' >&2; exit 1; }

echo 'PASS test_restore_checks_phase2'
