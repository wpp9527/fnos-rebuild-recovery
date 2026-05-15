#!/bin/bash
pkill -f 'dashboard/server.py' || true
sleep 2
cd /opt/fnos-media/services/edict-localized/repo
nohup python3 dashboard/server.py --host 192.168.1.212 --port 17892 > /tmp/dash.log 2>&1 &
sleep 5
echo "Dashboard 重启完成"
