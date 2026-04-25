#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
FNOS_LATEST_ROOT="$TMP/fnos-latest"
OPENCLAW_LATEST_ROOT="$TMP/openclaw-latest"
SECRETS_TEMPLATE="$TMP/templates/.env.example"
SECRETS_REAL_DIR="$TMP/real"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT" \
  "$FNOS_LATEST_ROOT/services/media-stack" "$FNOS_LATEST_ROOT/services/openclaw" "$FNOS_LATEST_ROOT/manifests" \
  "$OPENCLAW_LATEST_ROOT/docs" "$OPENCLAW_LATEST_ROOT/scripts/backup" "$OPENCLAW_LATEST_ROOT/memory" \
  "$TMP/templates" "$SECRETS_REAL_DIR"

echo 'compose: yes' > "$FNOS_LATEST_ROOT/services/media-stack/docker-compose.yml"
echo '{"ok":true}' > "$FNOS_LATEST_ROOT/services/openclaw/openclaw.json"
echo 'layout: ok' > "$FNOS_LATEST_ROOT/manifests/managed_root_layout.yaml"
echo '# docs ok' > "$OPENCLAW_LATEST_ROOT/docs/restore.md"
echo '#!/usr/bin/env bash' > "$OPENCLAW_LATEST_ROOT/scripts/backup/run.sh"
echo '# memory ok' > "$OPENCLAW_LATEST_ROOT/memory/notes.md"
cat > "$SECRETS_TEMPLATE" <<'EOF'
OPENCLAW_BASE_URL=
OPENCLAW_API_TOKEN=
PRIMARY_CHANNEL_TOKEN=
EOF
cat > "$SECRETS_REAL_DIR/openclaw.env" <<'EOF'
OPENCLAW_BASE_URL=https://example.local
OPENCLAW_API_TOKEN=secret-token
PRIMARY_CHANNEL_TOKEN=primary-secret
EOF

RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" FNOS_LATEST_ROOT="$FNOS_LATEST_ROOT" bash "$ROOT/restore/layers/20-fnos.sh" apply
RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" OPENCLAW_LATEST_ROOT="$OPENCLAW_LATEST_ROOT" bash "$ROOT/restore/layers/40-openclaw.sh" apply
RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" SECRETS_TEMPLATE_PATH="$SECRETS_TEMPLATE" SECRETS_REAL_DIR="$SECRETS_REAL_DIR" bash "$ROOT/restore/layers/50-secrets.sh" apply

OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" SECRETS_TEMPLATE_PATH="$SECRETS_TEMPLATE" SECRETS_REAL_DIR="$SECRETS_REAL_DIR" bash "$ROOT/restore/layers/90-verify.sh" verify)"
printf '%s' "$OUT" | grep -Fq 'verify summary PASS' || { echo 'verify summary did not pass' >&2; exit 1; }

SUMMARY="$(find "$RESTORE_STATE_ROOT/reports" -maxdepth 1 -name 'verification-summary-*.md' | head -n 1)"
RESULT="$(find "$RESTORE_STATE_ROOT/reports" -maxdepth 1 -name 'verification-result-*.json' | head -n 1)"
[[ -n "$SUMMARY" && -f "$SUMMARY" ]] || { echo 'missing verification summary' >&2; exit 1; }
[[ -n "$RESULT" && -f "$RESULT" ]] || { echo 'missing verification result json' >&2; exit 1; }
grep -Fq 'fnos: PASS' "$SUMMARY" || { echo 'summary missing fnos pass' >&2; exit 1; }
grep -Fq 'openclaw: PASS' "$SUMMARY" || { echo 'summary missing openclaw pass' >&2; exit 1; }
grep -Fq 'secrets: PASS' "$SUMMARY" || { echo 'summary missing secrets pass' >&2; exit 1; }
grep -Fq '"overall_status": "PASS"' "$RESULT" || { echo 'json missing overall PASS' >&2; exit 1; }

echo 'PASS test_restore_verify_aggregation'
