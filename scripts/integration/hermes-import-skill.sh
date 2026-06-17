#!/usr/bin/env bash
# 从 Hermes Agent 导入技能到 OpenClaw
set -euo pipefail

HERMES_SKILLS="${HERMES_SKILLS:-$HOME/.hermes/skills}"
OPENCLAW_SKILLS="${OPENCLAW_SKILLS:-$HOME/.openclaw/workspace/skills}"
STAGING="${STAGING:-/tmp/hermes-skill-import}"

log() { echo "[hermes-import] $*"; }

# 用法
usage() {
  cat << EOF
Usage: hermes-import-skill.sh [OPTIONS] <skill-path>

从 Hermes Agent 导入技能到 OpenClaw。

选项:
  -l, --list          列出可导入的 Hermes 技能
  -c, --category CAT  指定技能类别
  -d, --dry-run       只显示将要执行的操作
  -h, --help          显示帮助

示例:
  # 列出可导入技能
  hermes-import-skill.sh --list

  # 导入特定技能
  hermes-import-skill.sh autonomous-ai-agents/hermes-agent

  # 导入整个类别
  hermes-import-skill.sh --category devops
EOF
}

list_skills() {
  log "Hermes 可导入技能:"
  echo
  find "$HERMES_SKILLS" -name "SKILL.md" | while read -r skill; do
    rel_path="${skill#$HERMES_SKILLS/}"
    rel_path="${rel_path%/SKILL.md}"
    echo "  $rel_path"
  done | sort
}

import_skill() {
  local skill_path="$1"
  local src="$HERMES_SKILLS/$skill_path"
  
  if [[ ! -f "$src/SKILL.md" ]]; then
    log "错误: 找不到技能 $skill_path"
    exit 1
  fi
  
  local skill_name
  skill_name=$(basename "$skill_path")
  local dest="$OPENCLAW_SKILLS/hermes-$skill_name"
  
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[DRY-RUN] mkdir -p $dest"
    echo "[DRY-RUN] cp -r $src/* $dest/"
    return
  fi
  
  mkdir -p "$dest"
  cp -r "$src"/* "$dest/"
  
  log "已导入: $skill_path → hermes-$skill_name"
}

# 解析参数
DRY_RUN=0
CATEGORY=""
SKILL_PATH=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--list)
      list_skills
      exit 0
      ;;
    -c|--category)
      CATEGORY="$2"
      shift 2
      ;;
    -d|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      SKILL_PATH="$1"
      shift
      ;;
  esac
done

# 执行
if [[ -n "$CATEGORY" ]]; then
  find "$HERMES_SKILLS/$CATEGORY" -name "SKILL.md" | while read -r skill; do
    rel_path="${skill#$HERMES_SKILLS/}"
    rel_path="${rel_path%/SKILL.md}"
    import_skill "$rel_path"
  done
elif [[ -n "$SKILL_PATH" ]]; then
  import_skill "$SKILL_PATH"
else
  usage
  exit 1
fi
