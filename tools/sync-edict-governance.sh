#!/usr/bin/env bash
set -euo pipefail

SRC="/opt/fnos-media/services/edict-localized/repo"
DST="/tmp/edict-governance-export"
REMOTE="git@github.com:wpp9527/edict-governance.git"
BRANCH="main"
GIT_NAME="wpp9527"
GIT_EMAIL="wangpengpeng9527@gmail.com"

if [ ! -d "$SRC" ]; then
  echo "[ERR] source repo not found: $SRC" >&2
  exit 1
fi

mkdir -p "$DST"
rsync -a --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='__pycache__' \
  --exclude='.pytest_cache' \
  "$SRC"/ "$DST"/

if [ ! -d "$DST/.git" ]; then
  git -C "$DST" init -b "$BRANCH"
  git -C "$DST" remote add origin "$REMOTE"
fi

git -C "$DST" config user.name "$GIT_NAME"
git -C "$DST" config user.email "$GIT_EMAIL"
git -C "$DST" remote set-url origin "$REMOTE"

git -C "$DST" add .
if git -C "$DST" diff --cached --quiet; then
  echo "[OK] no changes to sync"
  exit 0
fi

STAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
git -C "$DST" commit -m "sync: edict governance snapshot ($STAMP)"
git -C "$DST" push origin "$BRANCH"

echo "[OK] synced to $REMOTE"
