# Backend Architecture

## 模块边界

- `internal/config`：配置加载
- `internal/httpapi`：HTTP 路由与 handler
- `internal/app`：应用装配
- 后续规划：
  - `internal/auth`
  - `internal/rbac`
  - `internal/audit`
  - `internal/adapter/llnut`
  - `internal/pvf`
