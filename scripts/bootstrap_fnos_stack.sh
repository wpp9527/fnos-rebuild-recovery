#!/usr/bin/env bash
# fnos blank-machine bootstrap
# Purpose: install/restore current OpenClaw + Dashboard + ClawPanel + Hermes/OpenWebUI stack on a clean machine.
# Notes:
# - This script is intentionally conservative.
# - It templates local config but does NOT embed real secrets.
# - Fill .env / config templates before production use.

set -euo pipefail

ROOT_DEFAULT="/opt/fnos-media"
STACK_DEFAULT="/opt/fnos-media-stack"
SERVICES_DEFAULT="$ROOT_DEFAULT/services"
OPENCLAW_HOME_DEFAULT="/root/.openclaw"
TZ_DEFAULT="Asia/Shanghai"

ROOT_DIR="${ROOT_DIR:-$ROOT_DEFAULT}"
STACK_DIR="${STACK_DIR:-$STACK_DEFAULT}"
SERVICES_DIR="${SERVICES_DIR:-$SERVICES_DEFAULT}"
OPENCLAW_HOME="${OPENCLAW_HOME:-$OPENCLAW_HOME_DEFAULT}"
TZ="${TZ:-$TZ_DEFAULT}"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups/bootstrap-$(date +%Y%m%d-%H%M%S)}"
DRY_RUN="${DRY_RUN:-0}"
INSTALL_MEDIA_STACK="${INSTALL_MEDIA_STACK:-0}"
RESTORE_CHANNEL_SEED="${RESTORE_CHANNEL_SEED:-0}"
CHANNEL_SEED_ARCHIVE="${CHANNEL_SEED_ARCHIVE:-}"
MEDIA_PROXY_ENABLED="${MEDIA_PROXY_ENABLED:-0}"
MEDIA_PROXY_HOST="${MEDIA_PROXY_HOST:-192.168.1.213}"
MEDIA_PROXY_PORT="${MEDIA_PROXY_PORT:-7890}"
MEDIA_PROXY_TYPE="${MEDIA_PROXY_TYPE:-http}"
MEDIA_PROXY_BYPASS="${MEDIA_PROXY_BYPASS:-localhost,127.0.0.1,192.168.1.0/24}"

EDICT_REPO="${EDICT_REPO:-$SERVICES_DIR/edict-localized/repo}"
CLAWPANEL_DIR="${CLAWPANEL_DIR:-$SERVICES_DIR/clawpanel/app}"
HERMES_WEBUI_DIR="${HERMES_WEBUI_DIR:-$SERVICES_DIR/hermes-openwebui}"
HERMES_AGENT_DIR="${HERMES_AGENT_DIR:-$SERVICES_DIR/hermes-agent/app}"
MEDIA_STACK_COMPOSE="${MEDIA_STACK_COMPOSE:-$STACK_DIR/docker-compose.yml}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${GREEN}✅ $*${NC}"; }
info() { echo -e "${BLUE}ℹ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
err() { echo -e "${RED}❌ $*${NC}"; }
run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY_RUN: $*"
  else
    eval "$@"
  fi
}
need_cmd() { command -v "$1" >/dev/null 2>&1 || { err "missing command: $1"; exit 1; }; }

banner() {
  cat <<EOF
============================================================
 FNOS stack bootstrap
 root=$ROOT_DIR
 services=$SERVICES_DIR
 openclaw_home=$OPENCLAW_HOME
 dry_run=$DRY_RUN
============================================================
EOF
}

check_deps() {
  info "Checking system dependencies"
  need_cmd bash
  need_cmd git
  need_cmd curl
  need_cmd python3
  need_cmd docker
  need_cmd sed
  need_cmd awk
  if ! command -v docker >/dev/null 2>&1; then
    err "docker is required"
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    err "docker daemon not ready or current user has no access"
    exit 1
  fi
  log "Dependencies OK"
}

prepare_dirs() {
  info "Preparing base directories"
  run "mkdir -p '$ROOT_DIR' '$SERVICES_DIR' '$STACK_DIR' '$BACKUP_DIR' '$OPENCLAW_HOME'"
  log "Directories prepared"
}

backup_existing() {
  info "Backing up existing high-value state"
  run "mkdir -p '$BACKUP_DIR'"
  local paths=(
    "$OPENCLAW_HOME/openclaw.json"
    "$OPENCLAW_HOME/agents"
    "$OPENCLAW_HOME/workspace"
    "$SERVICES_DIR/edict-localized"
    "$SERVICES_DIR/clawpanel"
    "$SERVICES_DIR/hermes-openwebui"
    "$SERVICES_DIR/hermes-agent"
    "$STACK_DIR"
  )
  for p in "${paths[@]}"; do
    if [[ -e "$p" ]]; then
      run "cp -a '$p' '$BACKUP_DIR/'"
    fi
  done
  log "Backup finished at $BACKUP_DIR"
}

archive_existing() {
  info "Creating compressed backup archive"
  local archive_path="$BACKUP_DIR.tar.gz"
  if [[ -d "$BACKUP_DIR" ]]; then
    run "tar -C '$(dirname "$BACKUP_DIR")' -czf '$archive_path' '$(basename "$BACKUP_DIR")'"
    log "Archive created: $archive_path"
  fi
}

ensure_openclaw() {
  info "Ensuring OpenClaw exists"
  if command -v openclaw >/dev/null 2>&1; then
    log "OpenClaw CLI already present: $(openclaw --version 2>/dev/null || echo OK)"
  else
    warn "OpenClaw CLI not found. Install it before running this script fully."
    warn "Example: npm i -g @qingchencloud/openclaw-zh"
  fi
  run "mkdir -p '$OPENCLAW_HOME/workspace'"
}

generate_templates() {
  info "Generating local config templates"
  run "mkdir -p '$ROOT_DIR/deploy-templates'"
  cat > "$ROOT_DIR/deploy-templates/stack.env.example" <<EOF
TZ=$TZ
OPENCLAW_HOME=$OPENCLAW_HOME
OPENCLAW_URL=http://127.0.0.1:18789
OPENWEBUI_PORT=3000
CLAWPANEL_URL=http://127.0.0.1:1420
EDICT_DASHBOARD_HOST=127.0.0.1
EDICT_DASHBOARD_PORT=17892
# Fill secrets below before production use
OPENAI_API_KEY=
HOMARR_AUTH_USERNAME=
HOMARR_AUTH_PASSWORD=
HALO_INITIALIZER_PASSWORD=
EOF
  cat > "$ROOT_DIR/deploy-templates/media-stack.env.example" <<EOF
TZ=$TZ
PUID=0
PGID=0
QBITTORRENT_WEBUI_PORT=8086
PROWLARR_PORT=9696
RADARR_PORT=7878
SONARR_PORT=8989
BAZARR_PORT=6767
JACKETT_PORT=9117
SEERR_PORT=5055
# Optional outbound proxy for indexer scraping and metadata calls.
# qBittorrent should remain direct/no proxy.
MEDIA_PROXY_ENABLED=0
MEDIA_PROXY_TYPE=http
MEDIA_PROXY_HOST=192.168.1.213
MEDIA_PROXY_PORT=7890
MEDIA_PROXY_BYPASS=localhost,127.0.0.1,192.168.1.0/24
# Never force internal LAN calls through an outbound proxy.
HTTP_PROXY=
HTTPS_PROXY=
ALL_PROXY=
NO_PROXY=localhost,127.0.0.1,192.168.1.0/24
EOF
  log "Wrote $ROOT_DIR/deploy-templates/stack.env.example"
  log "Wrote $ROOT_DIR/deploy-templates/media-stack.env.example"
}

install_edict_dashboard() {
  info "Installing/refreshing Edict dashboard"
  if [[ ! -d "$EDICT_REPO" ]]; then
    err "Edict repo missing: $EDICT_REPO"
    return 1
  fi
  run "cd '$EDICT_REPO' && bash ./install.sh"
  run "mkdir -p '$EDICT_REPO/dashboard/dist'"
  if [[ -d "$EDICT_REPO/edict/frontend" ]]; then
    if command -v npm >/dev/null 2>&1; then
      run "cd '$EDICT_REPO/edict/frontend' && npm install && npm run build"
      run "rsync -a --delete '$EDICT_REPO/edict/frontend/dist/' '$EDICT_REPO/dashboard/dist/'"
    else
      warn "npm not found; skipped frontend build"
    fi
  fi
  log "Edict dashboard install step complete"
}

install_clawpanel() {
  info "Installing/starting ClawPanel"
  if [[ ! -f "$CLAWPANEL_DIR/docker-compose.yml" ]]; then
    err "ClawPanel compose missing: $CLAWPANEL_DIR/docker-compose.yml"
    return 1
  fi
  run "cd '$CLAWPANEL_DIR' && docker compose up -d --build"
  log "ClawPanel started"
}

install_hermes_webui() {
  info "Installing/starting Hermes Open WebUI"
  if [[ ! -f "$HERMES_WEBUI_DIR/docker-compose.yml" ]]; then
    err "Hermes OpenWebUI compose missing: $HERMES_WEBUI_DIR/docker-compose.yml"
    return 1
  fi
  warn "Before production use, replace API key/env in $HERMES_WEBUI_DIR/docker-compose.yml"
  run "cd '$HERMES_WEBUI_DIR' && docker compose up -d"
  log "Hermes OpenWebUI started"
}

install_hermes_agent() {
  info "Preparing Hermes Agent"
  if [[ ! -f "$HERMES_AGENT_DIR/setup-hermes.sh" ]]; then
    warn "Hermes Agent setup script missing: $HERMES_AGENT_DIR/setup-hermes.sh"
    return 0
  fi
  run "cd '$HERMES_AGENT_DIR' && bash ./setup-hermes.sh"
  log "Hermes Agent prepared"
}

install_media_stack() {
  if [[ "$INSTALL_MEDIA_STACK" != "1" ]]; then
    info "Media stack skipped (INSTALL_MEDIA_STACK=0)"
    return 0
  fi
  info "Installing optional media stack"
  if [[ ! -f "$MEDIA_STACK_COMPOSE" ]]; then
    err "Media stack compose missing: $MEDIA_STACK_COMPOSE"
    return 1
  fi
  run "cd '$STACK_DIR' && docker compose up -d"
  log "Media stack started"
}

write_media_proxy_plan() {
  info "Writing migration rehearsal notes for media proxy policy"
  cat > "$ROOT_DIR/deploy-templates/media-proxy-policy.md" <<EOF
# Media Proxy Policy

Detected/default outbound proxy:
- type: $MEDIA_PROXY_TYPE
- host: $MEDIA_PROXY_HOST
- port: $MEDIA_PROXY_PORT
- bypass: $MEDIA_PROXY_BYPASS

Apply proxy to:
- Prowlarr
- Radarr
- Sonarr
- Bazarr
- Jackett (only after confirming its proxy type mapping on target host)

Do NOT apply proxy to:
- qBittorrent

Rule:
- All LAN and localhost traffic must bypass proxy.
- qBittorrent remains direct to avoid tracker/download path side effects.
EOF
  log "Wrote $ROOT_DIR/deploy-templates/media-proxy-policy.md"
}

restore_channel_seed() {
  if [[ "$RESTORE_CHANNEL_SEED" != "1" ]]; then
    info "Channel seed restore skipped"
    return 0
  fi
  if [[ -z "$CHANNEL_SEED_ARCHIVE" || ! -f "$CHANNEL_SEED_ARCHIVE" ]]; then
    err "RESTORE_CHANNEL_SEED=1 but CHANNEL_SEED_ARCHIVE missing"
    return 1
  fi
  info "Restoring optional channel seed archive"
  run "mkdir -p '$SERVICES_DIR/openclaw-channels'"
  run "tar -xf '$CHANNEL_SEED_ARCHIVE' -C '$SERVICES_DIR'"
  log "Channel seed restored"
}

healthcheck_media_stack() {
  if [[ "$INSTALL_MEDIA_STACK" != "1" ]]; then
    info "Media stack healthcheck skipped (INSTALL_MEDIA_STACK=0)"
    return 0
  fi
  info "Running post-start media stack healthcheck"
  python3 - <<'PY'
import sys, urllib.request
checks = [
    ("Bazarr", "http://127.0.0.1:6767"),
    ("Prowlarr", "http://127.0.0.1:9696"),
    ("Jackett", "http://127.0.0.1:9117"),
    ("Sonarr", "http://127.0.0.1:8989"),
    ("Radarr", "http://127.0.0.1:7878"),
]
failed = []
for name, url in checks:
    try:
        req = urllib.request.Request(url, method='GET')
        with urllib.request.urlopen(req, timeout=8) as r:
            print(f"{name}: HTTP {r.status}")
    except Exception as e:
        failed.append((name, str(e)))
if failed:
    print("Healthcheck failures:")
    for name, err in failed:
        print(f"- {name}: {err}")
    sys.exit(1)
PY
  log "Media stack healthcheck passed"
}

print_next_steps() {
  cat <<EOF

Next steps:
1. Fill secrets in: $ROOT_DIR/deploy-templates/stack.env.example
2. Verify OpenClaw Gateway is running and reachable at http://127.0.0.1:18789
3. Verify dashboard:
   cd $EDICT_REPO && python3 dashboard/server.py --host 127.0.0.1 --port 17892
4. Verify ClawPanel at :1420 and Hermes/Open WebUI at :3000
5. If migrating from old host, rsync runtime/config/data into:
   - $OPENCLAW_HOME
   - $SERVICES_DIR/edict-localized/repo/data (or canonical runtime data path)
   - app config dirs under $STACK_DIR
EOF
}

main() {
  banner
  check_deps
  prepare_dirs
  backup_existing
  ensure_openclaw
  generate_templates
  write_media_proxy_plan
  install_edict_dashboard
  install_clawpanel
  install_hermes_webui
  install_hermes_agent
  install_media_stack
  healthcheck_media_stack
  restore_channel_seed
  archive_existing
  print_next_steps
  log "Bootstrap flow complete"
}

main "$@"
