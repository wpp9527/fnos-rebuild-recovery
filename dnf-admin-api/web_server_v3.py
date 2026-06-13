#!/usr/bin/env python3
"""
DNF Admin API v3.0 Web 服务器
"""

import json
import os
from http.server import HTTPServer, SimpleHTTPRequestHandler
import urllib.request

API_BASE = "http://127.0.0.1:18883/api"

class WebHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/api/'):
            self.proxy_api()
            return
        
        if self.path == '/' or self.path == '':
            self.path = '/index.html'
        
        file_path = self.translate_path(self.path)
        if os.path.exists(file_path) and os.path.isfile(file_path):
            return SimpleHTTPRequestHandler.do_GET(self)
        
        self.path = '/index.html'
        return SimpleHTTPRequestHandler.do_GET(self)
    
    def proxy_api(self):
        try:
            url = f"{API_BASE}{self.path[4:]}"
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req, timeout=10) as response:
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
    os.chdir('/root/.openclaw/workspace/dnf-admin-api/frontend-v3')
    server = HTTPServer(('0.0.0.0', port), WebHandler)
    print(f"[*] DNF Admin Web 服务器启动在端口 {port}")
    server.serve_forever()
