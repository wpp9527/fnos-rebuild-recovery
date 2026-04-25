#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOC="$ROOT/docs/recovery-drill-report-2026-04-26.md"
[[ -f "$DOC" ]] || { echo 'drill report missing' >&2; exit 1; }
grep -Fq 'Secrets | **PASS**' "$DOC" || { echo 'missing secrets pass result' >&2; exit 1; }
grep -Fq 'secrets blocker has been resolved' "$DOC" || { echo 'missing resolved note' >&2; exit 1; }
grep -q '| PVE.*PASS' "$DOC" || { echo 'missing pve result' >&2; exit 1; }
grep -q '| fnOS.*PASS' "$DOC" || { echo 'missing fnos result' >&2; exit 1; }
grep -q '| OpenClaw.*PASS' "$DOC" || { echo 'missing openclaw result' >&2; exit 1; }
echo 'PASS test_recovery_drill_report_documents_secrets_blocker'
