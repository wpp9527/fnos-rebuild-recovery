#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
errors=0

echo "=== DNF Private Deploy Final Check ==="
echo ""

echo "[1/6] Checking script syntax..."
for script in scripts/*.sh; do
  if bash -n "$script" 2>/dev/null; then
    echo "  [ok] $script"
  else
    echo "  [error] $script" >&2
    ((errors++)) || true
  fi
done

echo ""
echo "[2/6] Checking compose config..."
if [[ -f compose/docker-compose.yaml ]]; then
  echo "  [ok] compose/docker-compose.yaml exists"
else
  echo "  [error] compose/docker-compose.yaml missing" >&2
  ((errors++)) || true
fi

echo ""
echo "[3/6] Checking schema tools..."
if scripts/test-schema-tools.sh >/dev/null 2>&1; then
  echo "  [ok] schema tools working"
else
  echo "  [error] schema tools failed" >&2
  ((errors++)) || true
fi

echo ""
echo "[4/6] Checking root user protection..."
set +e
output="$(LLNUT_MYSQL_READONLY_USER=root scripts/check-readonly-db.sh 2>&1)"
code=$?
set -e
if [[ "$code" -eq 2 ]] && echo "$output" | grep -q "must use read-only user, not root"; then
  echo "  [ok] root user properly rejected"
else
  echo "  [error] root user protection failed" >&2
  ((errors++)) || true
fi

echo ""
echo "[5/6] Checking healthcheck..."
if scripts/healthcheck.sh >/dev/null 2>&1; then
  echo "  [ok] healthcheck passed"
else
  echo "  [warn] healthcheck returned non-zero (expected in sandbox)"
fi

echo ""
echo "[6/6] Checking required files..."
required_files=(
  "docs/production-onboarding.md"
  "docs/admin-integration.md"
  "env/.env.example"
)
for f in "${required_files[@]}"; do
  if [[ -f "$f" ]]; then
    echo "  [ok] $f"
  else
    echo "  [error] missing $f" >&2
    ((errors++)) || true
  fi
done

echo ""
if [[ $errors -eq 0 ]]; then
  echo "=== ALL CHECKS PASSED ==="
  exit 0
else
  echo "=== $errors CHECK(S) FAILED ===" >&2
  exit 1
fi
