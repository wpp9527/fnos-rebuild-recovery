# Data Model Outline

## 管理后台自有库

### admins
- id
- username
- password_hash
- status
- created_at
- updated_at

### roles
- id
- key
- name
- description

### permissions
- id
- key
- name
- group_name

### admin_role_rel
- admin_id
- role_id

### audit_logs
- id
- operator_id
- action
- target_type
- target_id
- request_summary
- result_summary
- created_at

### favorites
- id
- admin_id
- type
- ref_id
- payload

### presets
- id
- admin_id
- type
- name
- payload

## 游戏库适配层

首版不在公开仓直接固化具体表结构，而通过 `adapter/llnut` 做隔离，避免业务层直接依赖现网表名。
