#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOC="$ROOT/docs/github-recovery-guide.md"
[[ -f "$DOC" ]] || { echo 'github recovery guide missing' >&2; exit 1; }
grep -Fq 'git clone https://github.com/wpp9527/fnos-rebuild-recovery' "$DOC" || { echo 'missing clone command' >&2; exit 1; }
grep -Fq 'restore/restore-all.sh plan' "$DOC" || { echo 'missing plan command' >&2; exit 1; }
grep -Fq 'restore/restore-all.sh apply' "$DOC" || { echo 'missing apply command' >&2; exit 1; }
grep -Fq '灾难恢复场景' "$DOC" || { echo 'missing disaster recovery scenarios' >&2; exit 1; }
echo 'PASS test_github_recovery_guide_exists'
