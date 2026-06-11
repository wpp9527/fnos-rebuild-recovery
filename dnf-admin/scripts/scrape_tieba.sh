#!/bin/bash

# 百度贴吧数据采集脚本
# 用法: ./scrape_tieba.sh <贴吧名> [页数]

TIEBA_NAME=${1:-dnf}
PAGES=${2:-5}
SERVER="192.168.1.204"
PORT="18882"
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluIiwicm9sZSI6ImFkbWluIiwiZXhwIjoxNzgxMjgzNDcxLCJpYXQiOjE3ODExOTcwNzF9.avPMNq2Ev_s93sJFo-UYAa69Cn8V4xGy5uInFjvto_0"

echo "开始采集贴吧: $TIEBA_NAME (页数: $PAGES)"

# 调用采集 API
curl -s -X POST "http://$SERVER:$PORT/api/v1/tieba/scrape/$TIEBA_NAME?pages=$PAGES" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

echo ""
echo "采集完成！"
