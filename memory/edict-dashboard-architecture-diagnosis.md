# Edict Dashboard 架构诊断报告

## 问题概述

Dashboard 显示"状态不对"，具体表现：
- Agent 技能配置丢失（显示"0 技能"）
- 数据源指向错误目录

## 架构分析

### 正确的数据流架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    OpenClaw Runtime                              │
│                                                                  │
│  ~/.openclaw/workspace-main/data/                               │
│  ├── agent_config.json    (Agent 配置 + 技能列表)                │
│  ├── tasks_source.json    (任务数据)                            │
│  ├── live_status.json     (实时状态)                            │
│  └── officials_stats.json (官员统计)                            │
│                                                                  │
│  ~/.openclaw/workspace-{agent_id}/skills/                       │
│  └── {skill_name}/SKILL.md  (各 Agent 的技能文件)                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    Dashboard Server (server.py)
                    数据源: EDICT_TASK_DATA_DIR 环境变量
                    或默认: ~/.openclaw/workspace-main/data
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Edict Dashboard (Web UI)                      │
│                    http://localhost:17892                        │
└─────────────────────────────────────────────────────────────────┘
```

### 问题根因

1. **systemd 服务配置缺失环境变量**
   - 文件: `/etc/systemd/system/edict-dashboard.service`
   - 问题: 未设置 `EDICT_TASK_DATA_DIR` 环境变量
   - 结果: Dashboard 回退到 `edict-localized/repo/data` 目录
   - 该目录的配置文件过期或为空

2. **数据源目录分离**
   - 正确数据源: `~/.openclaw/workspace-main/data/`
   - 回退数据源: `/opt/fnos-media/services/edict-localized/repo/data/`
   - 两者未同步，导致配置丢失

## 修复措施

### 1. 更新 systemd 服务配置

```ini
# /etc/systemd/system/edict-dashboard.service
[Service]
Environment="EDICT_TASK_DATA_DIR=/opt/fnos-media/services/openclaw/home/.openclaw/workspace-main/data"
```

### 2. 同步配置文件

将正确的配置文件从 `workspace-main/data/` 同步到 `edict-localized/repo/data/`：
- agent_config.json
- tasks_source.json
- live_status.json
- officials_stats.json
- agents_status.json

### 3. 验证数据源

```bash
# 检查日志中的数据源
journalctl -u edict-dashboard | grep "任务数据源"

# 应显示: 任务数据源: /opt/fnos-media/services/openclaw/home/.openclaw/workspace-main/data
```

## 关键文件位置

| 文件 | 路径 | 用途 |
|------|------|------|
| systemd 服务 | `/etc/systemd/system/edict-dashboard.service` | 服务配置 |
| server.py | `/opt/fnos-media/services/edict-localized/repo/dashboard/server.py` | Dashboard 服务 |
| 主数据源 | `~/.openclaw/workspace-main/data/` | 正确的配置数据 |
| 回退数据源 | `/opt/fnos-media/services/edict-localized/repo/data/` | 备用数据源 |

## 检测命令

```bash
# 1. 检查服务状态
systemctl status edict-dashboard

# 2. 检查数据源
curl -s http://localhost:17892/api/live-status | jq '.taskSource'

# 3. 检查 Agent 技能
curl -s http://localhost:17892/api/agent-config | jq '.agents[] | {id, skills: (.skills|length)}'

# 4. 检查日志
journalctl -u edict-dashboard --since "5 minutes ago" | grep "任务数据源"
```

## 修复后状态

- ✅ 服务运行正常
- ✅ 数据源指向正确目录
- ✅ 所有 Agent 有 16 个技能
- ✅ 任务数据正常加载
- ✅ 开机自动启动
