#!/bin/bash
# DNF Admin API v3.0 Web 服务器启动脚本
# 提供前端页面 + API 代理

cd "$(dirname "$0")"

echo "=== 启动 DNF Admin API v3.0 Web 服务器 ==="

# 1. 检查并创建 SSH 隧道
if ! nc -z 127.0.0.1 3307 2>/dev/null; then
    echo "[*] 创建 SSH 隧道..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no -f -N -L 3307:172.18.0.2:3306 root@192.168.1.204
    sleep 2
fi

# 2. 停止旧进程
pkill -f "python3.*api_server.py" 2>/dev/null || true
pkill -f "python3.*web_server.py" 2>/dev/null || true
sleep 1

# 3. 创建 Web 服务器
cat > web_server.py << 'PYTHON'
#!/usr/bin/env python3
"""
DNF Admin API v3.0 Web 服务器
提供前端页面 + API 代理
"""

import json
import os
from http.server import HTTPServer, SimpleHTTPRequestHandler
import urllib.request

# API 服务器地址
API_BASE = "http://127.0.0.1:18883/api/v2"

class WebHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        # 处理 API 请求
        if self.path.startswith('/api/'):
            self.proxy_api()
            return
        
        # 处理静态文件
        if self.path == '/' or self.path == '':
            self.path = '/index.html'
        
        # 检查文件是否存在
        file_path = self.translate_path(self.path)
        if os.path.exists(file_path) and os.path.isfile(file_path):
            return SimpleHTTPRequestHandler.do_GET(self)
        
        # 默认返回 index.html
        self.path = '/index.html'
        return SimpleHTTPRequestHandler.do_GET(self)
    
    def proxy_api(self):
        """代理 API 请求"""
        try:
            # /api/v2/health -> /health
            # /api/v2/character/list -> /character/list
            path_parts = self.path.split('/')
            if len(path_parts) >= 4:
                api_path = '/' + '/'.join(path_parts[3:])  # 移除 /api/v2
            else:
                api_path = '/'
            
            url = f"{API_BASE}{api_path}"
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req) as response:
                data = response.read()
                self.send_response(200)
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(data)
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

if __name__ == '__main__':
    port = 18884
    server = HTTPServer(('0.0.0.0', port), WebHandler)
    print(f"[*] DNF Admin Web 服务器启动在端口 {port}")
    print(f"[*] 访问地址: http://localhost:{port}")
    server.serve_forever()
PYTHON

# 4. 启动 Web 服务器
nohup python3 web_server.py > /tmp/dnf-admin-web.log 2>&1 &
sleep 2

# 5. 验证
if curl -s http://localhost:18884 > /dev/null 2>&1; then
    echo "[OK] Web 服务器启动成功"
    echo "[*] 访问地址: http://192.168.1.212:18884"
else
    echo "[ERR] Web 服务器启动失败"
    cat /tmp/dnf-admin-web.log
fi
