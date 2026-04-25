#!/usr/bin/env bash
# Publish selected secrets to NAS backup for recovery use.
# This script extracts recovery-critical secrets from runtime config
# and publishes them to /mnt/nas/backup/shared/secrets/latest/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

BACKUP_ROOT="${BACKUP_ROOT:-/mnt/nas/backup}"
SECRETS_DEST="$BACKUP_ROOT/shared/secrets/latest"

log "publish_secrets start"

# Ensure destination exists with restricted permissions
ensure_dir "$SECRETS_DEST"
chmod 700 "$SECRETS_DEST" 2>/dev/null || true

# ---- OpenClaw secrets ----
OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-/opt/fnos-media/services/openclaw/home/.openclaw/openclaw.json}"
CLAWPANEL_CONFIG="${CLAWPANEL_CONFIG:-/opt/fnos-media/services/openclaw/home/.openclaw/clawpanel.json}"

if [[ -f "$OPENCLAW_CONFIG" ]]; then
  # Extract primary channel token and base URL if present
  PRIMARY_TOKEN="$(jq -r '.agents.defaults.primaryChannelToken // empty' "$OPENCLAW_CONFIG" 2>/dev/null || true)"
  BASE_URL="$(jq -r '.agents.defaults.baseUrl // empty' "$OPENCLAW_CONFIG" 2>/dev/null || true)"
  
  if [[ -n "$PRIMARY_TOKEN" || -n "$BASE_URL" ]]; then
    cat > "$SECRETS_DEST/openclaw.env" <<EOF
# OpenClaw recovery secrets
# Generated: $(date -Is)
# DO NOT COMMIT THIS FILE
EOF
    [[ -n "$BASE_URL" ]] && echo "OPENCLAW_BASE_URL=$BASE_URL" >> "$SECRETS_DEST/openclaw.env"
    [[ -n "$PRIMARY_TOKEN" ]] && echo "PRIMARY_CHANNEL_TOKEN=$PRIMARY_TOKEN" >> "$SECRETS_DEST/openclaw.env"
    log "published openclaw.env"
  fi
fi

# ---- fnos-media-stack secrets ----
FNOS_MEDIA_ENV="${FNOS_MEDIA_ENV:-/opt/fnos-media-stack/.env}"

if [[ -f "$FNOS_MEDIA_ENV" ]]; then
  # Extract only recovery-critical secrets, not all env vars
  grep -E '^(HOMARR_AUTH_PASSWORD|HOMARR_SECRET_ENCRYPTION_KEY|HALO_INITIALIZER_PASSWORD|JELLYFIN_API_KEY|QBittorrent_PASSWORD)=' "$FNOS_MEDIA_ENV" > "$SECRETS_DEST/fnos-media-stack.env" 2>/dev/null || true
  
  if [[ -s "$SECRETS_DEST/fnos-media-stack.env" ]]; then
    {
      echo "# fnos-media-stack recovery secrets"
      echo "# Generated: $(date -Is)"
      echo "# DO NOT COMMIT THIS FILE"
      cat "$SECRETS_DEST/fnos-media-stack.env"
    } > "$SECRETS_DEST/fnos-media-stack.env.tmp"
    mv "$SECRETS_DEST/fnos-media-stack.env.tmp" "$SECRETS_DEST/fnos-media-stack.env"
    log "published fnos-media-stack.env"
  else
    rm -f "$SECRETS_DEST/fnos-media-stack.env"
  fi
fi

# ---- Channels secrets (if configured) ----
CHANNELS_SECRETS="${CHANNELS_SECRETS:-}"
if [[ -n "$CHANNELS_SECRETS" && -d "$CHANNELS_SECRETS" ]]; then
  ensure_dir "$SECRETS_DEST/channels"
  for f in "$CHANNELS_SECRETS"/*.env; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    cp "$f" "$SECRETS_DEST/channels/$name"
    log "published channels/$name"
  done
fi

# ---- Channels secrets from running containers ----
# Extract secrets from Docker containers that have them in env
if command -v docker >/dev/null 2>&1; then
  ensure_dir "$SECRETS_DEST/channels"
  
  # Feishu channel
  FEISHU_ENV=$(docker inspect feishu-observe --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || true)
  if [[ -n "$FEISHU_ENV" ]]; then
    FEISHU_SECRET=$(echo "$FEISHU_ENV" | grep '^FEISHU_APP_SECRET=' | cut -d= -f2)
    OPENAI_KEY=$(echo "$FEISHU_ENV" | grep '^OPENAI_API_KEY=' | cut -d= -f2)
    if [[ -n "$FEISHU_SECRET" || -n "$OPENAI_KEY" ]]; then
      {
        echo "# Feishu channel recovery secrets"
        echo "# Generated: $(date -Is)"
        [[ -n "$FEISHU_SECRET" ]] && echo "FEISHU_APP_SECRET=$FEISHU_SECRET"
        [[ -n "$OPENAI_KEY" ]] && echo "OPENAI_API_KEY=$OPENAI_KEY"
      } > "$SECRETS_DEST/channels/feishu.env"
      log "published channels/feishu.env"
    fi
  fi
  
  # QQ channel
  QQ_ENV=$(docker inspect qq-observe --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || true)
  if [[ -n "$QQ_ENV" ]]; then
    QQ_SECRET=$(echo "$QQ_ENV" | grep '^QQ_APP_SECRET=' | cut -d= -f2)
    OPENAI_KEY=$(echo "$QQ_ENV" | grep '^OPENAI_API_KEY=' | cut -d= -f2)
    if [[ -n "$QQ_SECRET" || -n "$OPENAI_KEY" ]]; then
      {
        echo "# QQ channel recovery secrets"
        echo "# Generated: $(date -Is)"
        [[ -n "$QQ_SECRET" ]] && echo "QQ_APP_SECRET=$QQ_SECRET"
        [[ -n "$OPENAI_KEY" ]] && echo "OPENAI_API_KEY=$OPENAI_KEY"
      } > "$SECRETS_DEST/channels/qq.env"
      log "published channels/qq.env"
    fi
  fi
  
  # OpenClaw gateway token (from any container that has it)
  GATEWAY_TOKEN=$(docker inspect feishu-observe --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^OPENCLAW_GATEWAY_AUTH_TOKEN=' | cut -d= -f2 | head -n 1 || true)
  if [[ -n "$GATEWAY_TOKEN" ]]; then
    {
      echo "# OpenClaw gateway recovery secrets"
      echo "# Generated: $(date -Is)"
      echo "OPENCLAW_GATEWAY_AUTH_TOKEN=$GATEWAY_TOKEN"
    } > "$SECRETS_DEST/openclaw.env"
    log "published openclaw.env (from container)"
  fi
fi

# Set restrictive permissions on all secret files
find "$SECRETS_DEST" -type f -exec chmod 600 {} \; 2>/dev/null || true

log "publish_secrets complete: $SECRETS_DEST"
