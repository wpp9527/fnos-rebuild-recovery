#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOC="$ROOT/docs/recovery-drill-report-2026-04-26.md"
[[ -f "$DOC" ]] || { echo 'drill report missing' >&2; exit 1; }
grep -Fq 'secrets are not in the backup path' "$DOC" || { echo 'missing secrets gap note' >&2; exit 1; }
grep -q '| PVE.*PASS' "$DOC" || { echo 'missing pve result' >&2; exit 1; }
grep -q '| fnOS.*PASS' "$DOC" || { echo 'missing fnos result' >&2; exit 1; }
grep -q '| OpenClaw.*PASS' "$DOC" || { echo 'missing openclaw result' >&2; exit 1; }
grep -Fq 'Secrets | BLOCK' "$DOC" || { echo 'missing secrets block result' >&2; exit 1; }
echo 'PASS test_recovery_drill_report_documents_secrets_blocker'
