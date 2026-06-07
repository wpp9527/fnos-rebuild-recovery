#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
ENV_FILE="${ENV_FILE:-env/.env.example}"
docker compose --env-file "$ENV_FILE" -f compose/docker-compose.yaml up -d
