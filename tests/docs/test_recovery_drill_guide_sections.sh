#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOC="$ROOT/docs/recovery-drill-guide.md"
[[ -f "$DOC" ]] || { echo 'recovery drill guide missing' >&2; exit 1; }
grep -Fq 'GitHub + NAS dual entry' "$DOC" || { echo 'missing dual entry section' >&2; exit 1; }
grep -Fq 'restore-all' "$DOC" || { echo 'missing restore-all section' >&2; exit 1; }
grep -Fq 'fnos-media-stack' "$DOC" || { echo 'missing fnos-media-stack section' >&2; exit 1; }
grep -Fq 'runtime audit' "$DOC" || { echo 'missing runtime audit section' >&2; exit 1; }
grep -Fq 'weekly backup verification' "$DOC" || { echo 'missing weekly backup verification section' >&2; exit 1; }
echo 'PASS test_recovery_drill_guide_sections'
