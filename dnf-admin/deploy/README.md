# DNF Admin Pro 部署说明

## 快速启动

### 方案 1: 使用 Docker Compose (推荐)

```bash
cd /root/.openclaw/workspace/dnf-admin/deploy
docker-compose up -d
```

### 方案 2: 手动启动

```bash
# 1. 启动 MySQL/MariaDB
docker run -d --name dnf-mysql \
  -e MYSQL_ROOT_PASSWORD=*** \
  -e MYSQL_DATABASE=dnf_service \
  -e MYSQL_USER=dnf_admin \
  -e MYSQL_PASSWORD=*** \
  -v /root/.openclaw/workspace/dnf-admin/deploy/init.sql:/docker-entrypoint-initdb.d/init.sql:ro \
  -p 3307:3306 \
  mysql:5.7

# 2. 启动 PVF 服务
cd /root/.openclaw/workspace/dnf-admin/pvf-service
python app.py &

# 3. 启动后端
cd /root/.openclaw/workspace/dnf-admin
export DB_HOST=127.0.0.1
export DB_PORT=3307
export DB_NAME=dnf_service
export DB_USER=dnf_admin
export DB_PASSWORD=***
export JWT_SECRET=dnf-ad…2026
export PVF_SERVICE=http://127.0.0.1:5000
./dnf-admin-server &

# 4. 启动前端
cd /root/.openclaw/workspace/dnf-admin/frontend/dist
python3 -m http.server 882 &
```

## 访问地址

- 前端: http://localhost:882
- API: http://localhost:8080
- PVF: http://localhost:5000

## 默认账号

- 用户名: admin
- 密码: admin123

## 数据库配置

- Host: 127.0.0.1:3307
- Database: dnf_service
- User: dnf_admin
- Password: ***
