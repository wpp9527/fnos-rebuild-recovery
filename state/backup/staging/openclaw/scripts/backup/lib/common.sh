#!/usr/bin/env bash
set -euo pipefail

now_ts() {
  date +%Y-%m-%d-%H%M%S
}

log() {
  printf '[backup] %s\n' "$*"
}

ensure_dir() {
  mkdir -p "$1"
}

require_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    printf 'required directory missing: %s\n' "$dir" >&2
    exit 1
  fi
}

stage_tmp_dir() {
  local base="$1"
  local name="$2"
  echo "$base/.tmp-$name"
}
