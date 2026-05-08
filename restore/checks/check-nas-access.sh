#!/usr/bin/env bash
set -euo pipefail

if [[ -d /mnt/nas/backup ]]; then
  echo 'PASS nas-access: /mnt/nas/backup present'
else
  echo 'WARN nas-access: /mnt/nas/backup not present'
fi
