#!/usr/bin/env bash
set -euo pipefail

SRC="/opt/fnos-media/services/openclaw/home/.openclaw/workspace"
DST="/tmp/fnos-rebuild-recovery-export"
REMOTE="git@github.com:wpp9527/fnos-rebuild-recovery.git"
BRANCH="main"
GIT_NAME="wpp9527"
GIT_EMAIL="wangpengpeng9527@gmail.com"

if [ ! -d "$SRC" ]; then
  echo "[ERR] source repo not found: $SRC" >&2
  exit 1
fi

bootstrap_repo() {
  rm -rf "$DST"
  git clone --branch "$BRANCH" "$REMOTE" "$DST"
}

if [ ! -d "$DST/.git" ]; then
  bootstrap_repo
else
  git -C "$DST" remote set-url origin "$REMOTE"
  if ! git -C "$DST" fetch origin "$BRANCH" || \
     ! git -C "$DST" checkout "$BRANCH" || \
     ! git -C "$DST" pull --ff-only origin "$BRANCH"; then
    bootstrap_repo
  fi
fi

git -C "$DST" config user.name "$GIT_NAME"
git -C "$DST" config user.email "$GIT_EMAIL"

rsync -a --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='__pycache__' \
  --exclude='.pytest_cache' \
  "$SRC"/ "$DST"/

git -C "$DST" add .
if git -C "$DST" diff --cached --quiet; then
  echo "[OK] no changes to sync"
  exit 0
fi

STAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
git -C "$DST" commit -m "sync: recovery workspace snapshot ($STAMP)"
git -C "$DST" push origin "$BRANCH"

echo "[OK] synced to $REMOTE"
