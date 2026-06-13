#!/bin/bash
# DNF Admin API v3.0 启动脚本
# 实现全部14个推荐功能

cd "$(dirname "$0")"

echo "=== 启动 DNF Admin API v3.0 ==="
echo ""

# 1. 检查并创建 SSH 隧道
if ! nc -z 127.0.0.1 3307 2>/dev/null; then
    echo "[*] 创建 SSH 隧道到 192.168.1.204..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no -f -N -L 3307:172.18.0.2:3306 root@192.168.1.204
    sleep 2
fi

if nc -z 127.0.0.1 3307 2>/dev/null; then
    echo "[OK] SSH 隧道已就绪"
else
    echo "[ERR] SSH 隧道创建失败"
    exit 1
fi

# 2. 停止旧进程
pkill -f "python3.*api_server.py" 2>/dev/null || true
sleep 1

# 3. 启动 API 服务器
echo "[*] 启动 API 服务器..."
nohup python3 api_server.py > /tmp/dnf-admin-api.log 2>&1 &
sleep 3

# 4. 验证
if curl -s http://localhost:18883/api/v2/health > /dev/null 2>&1; then
    echo "[OK] API 服务器启动成功"
    echo ""
    echo "=== 功能列表 ==="
    echo "1.  角色查询:    http://localhost:18883/api/v2/character/list"
    echo "2.  物品查询:    http://localhost:18883/api/v2/item/search?q=武器"
    echo "3.  怪物图鉴:    http://localhost:18883/api/v2/monster/search?q=哥布林"
    echo "4.  技能查询:    http://localhost:18883/api/v2/skill/by-job?job=100"
    echo "5.  在线统计:    http://localhost:18883/api/v2/stats/online"
    echo "6.  经济监控:    http://localhost:18883/api/v2/stats/economy"
    echo "7.  副本统计:    http://localhost:18883/api/v2/stats/dungeon"
    echo "8.  PVP排行:    http://localhost:18883/api/v2/stats/pvp"
    echo "9.  封禁管理:    http://localhost:18883/api/v2/punish/list"
    echo "10. 邮件管理:    http://localhost:18883/api/v2/mail/list"
    echo "11. 活动管理:    http://localhost:18883/api/v2/event/list"
    echo "12. 贴吧关联:    http://localhost:18883/api/v2/tieba/link?id=1"
    echo "13. 反馈追踪:    http://localhost:18883/api/v2/feedback/list"
    echo "14. 版本监控:    http://localhost:18883/api/v2/version/monitor"
    echo ""
    echo "数据自检:      http://localhost:18883/api/v2/check/report"
    echo "异常检测:      http://localhost:18883/api/v2/check/anomaly"
    echo ""
else
    echo "[ERR] API 服务器启动失败"
    cat /tmp/dnf-admin-api.log
fi
