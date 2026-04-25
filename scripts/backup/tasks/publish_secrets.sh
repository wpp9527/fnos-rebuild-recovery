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

# ---- fnos-media-stack secrets from containers ----
if command -v docker >/dev/null 2>&1; then
  ensure_dir "$SECRETS_DEST/fnos-media-stack"
  
  # Homarr
  HOMARR_ENV=$(docker inspect homarr --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || true)
  if [[ -n "$HOMARR_ENV" ]]; then
    HOMARR_PASSWORD=$(echo "$HOMARR_ENV" | grep '^AUTH_PASSWORD=' | cut -d= -f2- || true)
    HOMARR_ENC_KEY=$(echo "$HOMARR_ENV" | grep '^SECRET_ENCRYPTION_KEY=' | cut -d= -f2- || true)
    if [[ -n "$HOMARR_PASSWORD" && "$HOMARR_PASSWORD" != '' ]]; then
      echo "HOMARR_AUTH_PASSWORD=$HOMARR_PASSWORD" >> "$SECRETS_DEST/fnos-media-stack/.env.tmp"
    fi
    if [[ -n "$HOMARR_ENC_KEY" && "$HOMARR_ENC_KEY" != '' ]]; then
      echo "HOMARR_SECRET_ENCRYPTION_KEY=$HOMARR_ENC_KEY" >> "$SECRETS_DEST/fnos-media-stack/.env.tmp"
    fi
  fi
  
  # Halo
  HALO_ENV=$(docker inspect halo-blog --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || true)
  if [[ -n "$HALO_ENV" ]]; then
    HALO_PASSWORD=$(echo "$HALO_ENV" | grep '^HALO_SECURITY_INITIALIZER_PASSWORD=' | cut -d= -f2- || true)
    if [[ -n "$HALO_PASSWORD" && "$HALO_PASSWORD" != '' ]]; then
      echo "HALO_INITIALIZER_PASSWORD=$HALO_PASSWORD" >> "$SECRETS_DEST/fnos-media-stack/.env.tmp"
    fi
  fi
  
  # Jellyfin
  JELLYFIN_ENV=$(docker inspect jellyfin --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || true)
  if [[ -n "$JELLYFIN_ENV" ]]; then
    JELLYFIN_KEY=$(echo "$JELLYFIN_ENV" | grep '^JELLYFIN_API_KEY=' | cut -d= -f2- || true)
    if [[ -n "$JELLYFIN_KEY" && "$JELLYFIN_KEY" != '' ]]; then
      echo "JELLYFIN_API_KEY=$JELLYFIN_KEY" >> "$SECRETS_DEST/fnos-media-stack/.env.tmp"
    fi
  fi
  
  # Finalize fnos-media-stack.env if we have any secrets
  if [[ -f "$SECRETS_DEST/fnos-media-stack/.env.tmp" ]]; then
    {
      echo "# fnos-media-stack recovery secrets"
      echo "# Generated: $(date -Is)"
      cat "$SECRETS_DEST/fnos-media-stack/.env.tmp"
    } > "$SECRETS_DEST/fnos-media-stack.env"
    rm -f "$SECRETS_DEST/fnos-media-stack/.env.tmp"
    log "published fnos-media-stack.env (from containers)"
  fi
  rm -rf "$SECRETS_DEST/fnos-media-stack"
fi

# ---- Channels secrets from running containers ----
# Extract secrets from Docker containers that have them in env
if command -v docker >/dev/null 2>&1; then
  ensure_dir "$SECRETS_DEST/channels"
  
  # Feishu channel
  FEISHU_ENV=$(docker inspect feishu-observe --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || true)
  if [[ -n "$FEISHU_ENV" ]]; then
    FEISHU_SECRET=$(echo "$FEISHU_ENV" | grep '^FEISHU_APP_SECRET=' | cut -d= -f2 || true)
    OPENAI_KEY=$(echo "$FEISHU_ENV" | grep '^OPENAI_API_KEY=' | cut -d= -f2 || true)
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
    QQ_SECRET=$(echo "$QQ_ENV" | grep '^QQ_APP_SECRET=' | cut -d= -f2 || true)
    OPENAI_KEY=$(echo "$QQ_ENV" | grep '^OPENAI_API_KEY=' | cut -d= -f2 || true)
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
  GATEWAY_ENV=$(docker inspect feishu-observe --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || true)
  if [[ -n "$GATEWAY_ENV" ]]; then
    GATEWAY_TOKEN=$(echo "$GATEWAY_ENV" | grep '^OPENCLAW_GATEWAY_AUTH_TOKEN=' | cut -d= -f2 | head -n 1 || true)
    if [[ -n "$GATEWAY_TOKEN" ]]; then
      {
        echo "# OpenClaw gateway recovery secrets"
        echo "# Generated: $(date -Is)"
        echo "OPENCLAW_GATEWAY_AUTH_TOKEN=$GATEWAY_TOKEN"
      } > "$SECRETS_DEST/openclaw.env"
      log "published openclaw.env (from container)"
    fi
  fi
fi

# Set restrictive permissions on all secret files
find "$SECRETS_DEST" -type f -exec chmod 600 {} \; 2>/dev/null || true

log "publish_secrets complete: $SECRETS_DEST"
