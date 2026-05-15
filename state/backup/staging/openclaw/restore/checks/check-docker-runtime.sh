#!/usr/bin/env bash
set -euo pipefail
if command -v docker >/dev/null 2>&1; then
  echo 'PASS docker-runtime: docker available'
else
  echo 'WARN docker-runtime: docker unavailable'
fi
