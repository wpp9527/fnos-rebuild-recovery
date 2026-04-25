#!/usr/bin/env bash
# Interactive Recovery Script
# Provides menu-driven recovery options
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default paths
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/nas/backup}"
TARGET_ROOT="${TARGET_ROOT:-/}"
SOURCE_MODE="${SOURCE_MODE:-hybrid}"

print_header() {
  clear
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║            fnos-rebuild-recovery 恢复向导                  ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
  echo
}

print_status() {
  echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
  echo -e "${RED}[✗]${NC} $1"
}

check_prerequisites() {
  local missing=0
  
  echo -e "\n${YELLOW}检查恢复环境...${NC}\n"
  
  # Check git
  if command -v git &>/dev/null; then
    print_status "Git: 已安装"
  else
    print_error "Git: 未安装"
    missing=1
  fi
  
  # Check docker
  if command -v docker &>/dev/null; then
    print_status "Docker: 已安装"
  else
    print_warning "Docker: 未安装 (某些恢复步骤可能需要)"
  fi
  
  # Check NAS access
  if [[ -d "$BACKUP_ROOT" ]]; then
    print_status "NAS 备份目录: 可访问 ($BACKUP_ROOT)"
  else
    print_warning "NAS 备份目录: 不可访问 ($BACKUP_ROOT)"
  fi
  
  # Check backup sources
  local sources=0
  [[ -d "$BACKUP_ROOT/pve/latest" ]] && { print_status "PVE 备份: 存在"; ((sources++)); }
  [[ -d "$BACKUP_ROOT/fnos/latest" ]] && { print_status "fnOS 备份: 存在"; ((sources++)); }
  [[ -d "$BACKUP_ROOT/services/openclaw/latest" ]] && { print_status "OpenClaw 备份: 存在"; ((sources++)); }
  [[ -d "$BACKUP_ROOT/shared/secrets/latest" ]] && { print_status "Secrets 备份: 存在"; ((sources++)); }
  
  if [[ $sources -eq 0 ]]; then
    print_error "未找到任何备份源"
    missing=1
  fi
  
  echo
  return $missing
}

show_main_menu() {
  echo -e "\n${BLUE}════════════════════════════════════════${NC}"
  echo -e "${BLUE}  主菜单${NC}"
  echo -e "${BLUE}════════════════════════════════════════${NC}\n"
  echo "  1) 完整恢复 (推荐)"
  echo "  2) 选择性恢复"
  echo "  3) 仅恢复配置"
  echo "  4) 仅恢复数据"
  echo "  5) 查看恢复计划"
  echo "  6) 验证恢复结果"
  echo "  7) 运行系统审计"
  echo "  0) 退出"
  echo
}

show_selective_menu() {
  echo -e "\n${BLUE}════════════════════════════════════════${NC}"
  echo -e "${BLUE}  选择性恢复${NC}"
  echo -e "${BLUE}════════════════════════════════════════${NC}\n"
  echo "  1) 恢复 PVE 配置"
  echo "  2) 恢复 fnOS 本地状态"
  echo "  3) 恢复 OpenClaw"
  echo "  4) 恢复 Services (docker-compose)"
  echo "  5) 恢复 Secrets"
  echo "  6) 恢复 fnos-media-stack"
  echo "  7) 恢复 Channels (Feishu/QQ)"
  echo "  8) 恢复 Hermes OpenWebUI"
  echo "  0) 返回主菜单"
  echo
}

read_choice() {
  local prompt="$1"
  local default="${2:-}"
  local input
  
  if [[ -n "$default" ]]; then
    echo -ne "${YELLOW}$prompt [$default]: ${NC}"
  else
    echo -ne "${YELLOW}$prompt: ${NC}"
  fi
  
  read -r input
  echo "${input:-$default}"
}

confirm() {
  local prompt="$1"
  local default="${2:-n}"
  local answer
  
  case "$default" in
    y|Y) echo -ne "${YELLOW}$prompt [Y/n]: ${NC}" ;;
    n|N) echo -ne "${YELLOW}$prompt [y/N]: ${NC}" ;;
  esac
  
  read -r answer
  case "${answer:-$default}" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

run_restore_layer() {
  local layer="$1"
  local action="${2:-apply}"
  
  echo -e "\n${GREEN}执行恢复: $layer ($action)${NC}\n"
  
  local env_vars=(
    "RESTORE_STATE_ROOT=$WORKSPACE_ROOT/state/restore"
    "RESTORE_TARGET_ROOT=$TARGET_ROOT"
    "PVE_LATEST_ROOT=$BACKUP_ROOT/pve/latest"
    "FNOS_LATEST_ROOT=$BACKUP_ROOT/fnos/latest"
    "OPENCLAW_LATEST_ROOT=$BACKUP_ROOT/services/openclaw/latest"
    "SECRETS_REAL_DIR=$BACKUP_ROOT/shared/secrets/latest"
    "SECRETS_TEMPLATE_PATH=$WORKSPACE_ROOT/restore/templates/secrets/.env.example"
  )
  
  case "$layer" in
    pve)
      "${env_vars[@]}" bash "$WORKSPACE_ROOT/restore/layers/10-pve.sh" "$action"
      ;;
    fnos)
      "${env_vars[@]}" bash "$WORKSPACE_ROOT/restore/layers/20-fnos.sh" "$action"
      ;;
    services)
      "${env_vars[@]}" bash "$WORKSPACE_ROOT/restore/layers/30-services.sh" "$action"
      ;;
    openclaw)
      "${env_vars[@]}" bash "$WORKSPACE_ROOT/restore/layers/40-openclaw.sh" "$action"
      ;;
    secrets)
      "${env_vars[@]}" bash "$WORKSPACE_ROOT/restore/layers/50-secrets.sh" "$action"
      ;;
    all)
      cd "$WORKSPACE_ROOT"
      FORCE_GITHUB_ACCESS=0 FORCE_NAS_ACCESS=1 \
        RESTORE_STATE_ROOT="$WORKSPACE_ROOT/state/restore" \
        RESTORE_TARGET_ROOT="$TARGET_ROOT" \
        PVE_LATEST_ROOT="$BACKUP_ROOT/pve/latest" \
        FNOS_LATEST_ROOT="$BACKUP_ROOT/fnos/latest" \
        OPENCLAW_LATEST_ROOT="$BACKUP_ROOT/services/openclaw/latest" \
        SECRETS_REAL_DIR="$BACKUP_ROOT/shared/secrets/latest" \
        SECRETS_TEMPLATE_PATH="$WORKSPACE_ROOT/restore/templates/secrets/.env.example" \
        bash restore/restore-all.sh "$action" --source nas
      ;;
  esac
}

do_full_restore() {
  print_header
  echo -e "${YELLOW}完整恢复模式${NC}"
  echo -e "\n这将恢复所有内容到目标目录。\n"
  
  echo "目标目录: $TARGET_ROOT"
  echo "备份源: $BACKUP_ROOT"
  echo
  
  if ! confirm "确认执行完整恢复?" "n"; then
    echo "已取消"
    return
  fi
  
  # Step 1: Plan
  echo -e "\n${BLUE}[1/3] 生成恢复计划...${NC}"
  run_restore_layer "all" "plan"
  
  # Step 2: Apply
  echo -e "\n${BLUE}[2/3] 执行恢复...${NC}"
  run_restore_layer "all" "apply"
  
  # Step 3: Verify
  if confirm "是否验证恢复结果?" "y"; then
    echo -e "\n${BLUE}[3/3] 验证恢复...${NC}"
    run_restore_layer "all" "verify"
  fi
  
  echo -e "\n${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}  恢复完成！${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "\n恢复目标: $TARGET_ROOT"
  echo -e "报告目录: $WORKSPACE_ROOT/state/restore/reports/"
}

do_selective_restore() {
  while true; do
    print_header
    show_selective_menu
    
    local choice
    choice=$(read_choice "请选择" "0")
    
    case "$choice" in
      1) run_restore_layer "pve" "apply" ;;
      2) run_restore_layer "fnos" "apply" ;;
      3) run_restore_layer "openclaw" "apply" ;;
      4) run_restore_layer "services" "apply" ;;
      5) run_restore_layer "secrets" "apply" ;;
      6)
        echo -e "\n恢复 fnos-media-stack..."
        mkdir -p "$TARGET_ROOT/opt/fnos-media-stack"
        if [[ -d "$BACKUP_ROOT/fnos/latest/fnos-media-stack" ]]; then
          cp -r "$BACKUP_ROOT/fnos/latest/fnos-media-stack/"* "$TARGET_ROOT/opt/fnos-media-stack/"
          print_status "fnos-media-stack 已恢复"
        else
          print_error "未找到 fnos-media-stack 备份"
        fi
        ;;
      7)
        echo -e "\n恢复 Channels..."
        mkdir -p "$TARGET_ROOT/opt/fnos-media/services/docker-stack/channels"
        if [[ -d "$BACKUP_ROOT/fnos/latest/services/docker-stack/channels" ]]; then
          cp -r "$BACKUP_ROOT/fnos/latest/services/docker-stack/channels/"* "$TARGET_ROOT/opt/fnos-media/services/docker-stack/channels/"
          print_status "Channels 已恢复"
        else
          print_error "未找到 Channels 备份"
        fi
        ;;
      8)
        echo -e "\n恢复 Hermes OpenWebUI..."
        mkdir -p "$TARGET_ROOT/opt/fnos-media/services/hermes-openwebui/data"
        if [[ -d "$BACKUP_ROOT/fnos/latest/services/hermes-openwebui/data" ]]; then
          cp -r "$BACKUP_ROOT/fnos/latest/services/hermes-openwebui/data/"* "$TARGET_ROOT/opt/fnos-media/services/hermes-openwebui/data/"
          print_status "Hermes OpenWebUI 已恢复"
        else
          print_error "未找到 Hermes 备份"
        fi
        ;;
      0) return ;;
      *) print_error "无效选择" ;;
    esac
    
    echo
    read -p "按回车继续..."
  done
}

do_config_only_restore() {
  print_header
  echo -e "${YELLOW}仅恢复配置${NC}"
  echo -e "\n这将恢复所有配置文件，但不恢复数据。\n"
  
  if ! confirm "确认执行?" "n"; then
    return
  fi
  
  # Restore configs only
  run_restore_layer "pve" "apply"
  run_restore_layer "secrets" "apply"
  
  # Restore compose files only (no data)
  mkdir -p "$TARGET_ROOT/services/fnos-media-stack"
  if [[ -f "$WORKSPACE_ROOT/restore/templates/services/fnos-media-stack/docker-compose.yml" ]]; then
    cp "$WORKSPACE_ROOT/restore/templates/services/fnos-media-stack/docker-compose.yml" \
       "$TARGET_ROOT/services/fnos-media-stack/"
    print_status "docker-compose.yml 已恢复"
  fi
  
  echo -e "\n${GREEN}配置恢复完成！${NC}"
}

do_data_only_restore() {
  print_header
  echo -e "${YELLOW}仅恢复数据${NC}"
  echo -e "\n这将恢复所有数据文件，但不恢复配置。\n"
  
  if ! confirm "确认执行?" "n"; then
    return
  fi
  
  run_restore_layer "fnos" "apply"
  run_restore_layer "openclaw" "apply"
  
  echo -e "\n${GREEN}数据恢复完成！${NC}"
}

do_show_plan() {
  print_header
  echo -e "${YELLOW}生成恢复计划...${NC}\n"
  
  run_restore_layer "all" "plan"
  
  echo -e "\n${GREEN}计划已生成，查看:${NC}"
  echo "  $WORKSPACE_ROOT/state/restore/restore-plan.md"
  echo
  read -p "按回车返回..."
}

do_verify() {
  print_header
  echo -e "${YELLOW}验证恢复结果...${NC}\n"
  
  run_restore_layer "all" "verify"
  
  echo -e "\n验证报告已生成:"
  echo "  $WORKSPACE_ROOT/state/restore/reports/"
  echo
  read -p "按回车返回..."
}

do_audit() {
  print_header
  echo -e "${YELLOW}运行系统审计...${NC}\n"
  
  AUDIT_REPORT_ROOT="$WORKSPACE_ROOT/state/backup/reports" \
    LIVE_COMPOSE_PATH="/opt/fnos-media-stack/docker-compose.yml" \
    TEMPLATE_COMPOSE_PATH="$WORKSPACE_ROOT/restore/templates/services/fnos-media-stack/docker-compose.yml" \
    SERVICE_CATALOG_PATH="$WORKSPACE_ROOT/restore/manifests/service-catalog.yaml" \
    bash "$WORKSPACE_ROOT/scripts/backup/audit_runtime_state.sh"
  
  echo -e "\n${GREEN}审计完成！${NC}"
  echo
  read -p "按回车返回..."
}

configure_paths() {
  print_header
  echo -e "${YELLOW}配置路径${NC}\n"
  
  TARGET_ROOT=$(read_choice "目标目录" "$TARGET_ROOT")
  BACKUP_ROOT=$(read_choice "备份目录" "$BACKUP_ROOT")
  
  echo -e "\n${GREEN}配置已更新${NC}"
  echo "  目标: $TARGET_ROOT"
  echo "  备份: $BACKUP_ROOT"
}

# Main entry point
main() {
  # Check if running as root for production restore
  if [[ "$TARGET_ROOT" == "/" && $EUID -ne 0 ]]; then
    print_warning "恢复到系统根目录需要 root 权限"
    echo "建议: sudo bash $0"
    echo
    if ! confirm "是否继续 (将恢复到临时目录)?" "y"; then
      exit 1
    fi
    TARGET_ROOT="/tmp/restore-$(date +%Y%m%d-%H%M%S)"
    print_status "目标目录已改为: $TARGET_ROOT"
  fi
  
  while true; do
    print_header
    
    # Check prerequisites on first run
    if ! check_prerequisites; then
      echo
      if ! confirm "环境检查发现问题，是否继续?" "n"; then
        exit 1
      fi
    fi
    
    show_main_menu
    
    local choice
    choice=$(read_choice "请选择" "1")
    
    case "$choice" in
      1) do_full_restore ;;
      2) do_selective_restore ;;
      3) do_config_only_restore ;;
      4) do_data_only_restore ;;
      5) do_show_plan ;;
      6) do_verify ;;
      7) do_audit ;;
      0)
        echo -e "\n${GREEN}再见！${NC}"
        exit 0
        ;;
      c|C) configure_paths ;;
      *)
        print_error "无效选择"
        sleep 1
        ;;
    esac
  done
}

# Run main
main "$@"
