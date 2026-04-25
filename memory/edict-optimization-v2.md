# Edict 任务链优化方案 v2

## 基于 Workflow + Agent-Orchestrator + Agent-Autonomy-Kit 的重构

---

## 一、现状问题

### 1. 状态不一致
- `JJC-20260421-002`: Done 但最后流转不是皇上
- 多数 Cancelled 任务仍启用 scheduler
- flow_log 和 state 不同步

### 2. 缺少 Workflow 模式
- 没有明确的错误处理声明
- 没有状态文件（cursor.json, seen.json, checkpoint.json）
- 没有锁文件机制

### 3. Agent 协作不规范
- 没有基于文件的通信协议（inbox/outbox）
- 没有明确的 agent 生命周期管理
- 没有任务队列机制

---

## 二、基于 Workflow Skill 的重构

### 核心模式迁移

```python
# 原 edict 模式
task = {
    "id": "JJC-xxx",
    "state": "Zhongshu",
    "org": "中书省",
    "flow_log": [...],
    # 分散的状态字段
}

# 新 workflow 模式
task = {
    "id": "JJC-xxx",
    "state": "Zhongshu",
    "org": "中书省",
    "_workflow": {
        # 来自 workflow skill 的模式
        "cursor": {"phase": "draft", "step": 2},
        "seen": ["taizi", "zhongshu"],
        "checkpoint": {
            "lastSuccess": "2026-04-20T17:07:18Z",
            "retryCount": 0,
            "nextAgent": "menxia"
        },
        # 错误处理声明
        "onError": "retry(3)",
        "onEmpty": "continue"
    },
    "_orchestrator": {
        # 来自 agent-orchestrator skill
        "decomposition": {
            "subtasks": ["draft", "review", "execute"],
            "dependencies": {"review": ["draft"], "execute": ["review"]}
        },
        "agents": {
            "draft": {"status": "completed", "agentId": "zhongshu"},
            "review": {"status": "running", "agentId": "menxia"},
            "execute": {"status": "pending", "agentId": null}
        }
    },
    "flow_log": [...],
}
```

### 状态管理

```python
# 添加 workflow 状态文件
def init_workflow_state(task_id):
    workflow_dir = get_task_data_dir() / 'workflows' / task_id
    workflow_dir.mkdir(parents=True, exist_ok=True)

    # 初始化状态文件
    (workflow_dir / 'cursor.json').write_text(json.dumps({
        "phase": "init",
        "step": 0
    }))

    (workflow_dir / 'seen.json').write_text(json.dumps([]))

    (workflow_dir / 'checkpoint.json').write_text(json.dumps({
        "lastSuccess": None,
        "retryCount": 0
    }))
```

---

## 三、基于 Agent-Orchestrator Skill 的重构

### Agent 通信协议

```python
# 为每个 agent 创建 workspace
def create_agent_workspace(agent_id, task_id):
    workspace = get_task_data_dir() / 'agents' / agent_id / task_id
    workspace.mkdir(parents=True, exist_ok=True)

    # 创建通信目录
    (workspace / 'inbox').mkdir()
    (workspace / 'outbox').mkdir()
    (workspace / 'workspace').mkdir()

    # 初始化状态
    (workspace / 'status.json').write_text(json.dumps({
        "state": "pending",
        "started": None,
        "completed": None
    }))

    return workspace
```

### 任务 Dispatch

```python
def dispatch_to_agent(agent_id, task_id, instructions):
    workspace = get_task_data_dir() / 'agents' / agent_id / task_id

    # 写入指令
    (workspace / 'inbox' / 'instructions.md').write_text(instructions)

    # 更新状态
    status = json.loads((workspace / 'status.json').read_text())
    status['state'] = 'running'
    status['started'] = now_iso()
    (workspace / 'status.json').write_text(json.dumps(status))

    # 唤醒 agent
    wake_agent(agent_id, f"新任务: {task_id}")
```

---

## 四、基于 Agent-Autonomy-Kit Skill 的重构

### 任务队列

```python
# 创建 tasks/QUEUE.md
def init_task_queue():
    queue_file = get_task_data_dir() / 'QUEUE.md'
    if not queue_file.exists():
        queue_file.write_text("""# Task Queue

## Ready
<!-- 任务已准备，等待 agent 接手 -->

## In Progress
<!-- 正在执行的任务 -->

## Blocked
<!-- 阻塞的任务 -->

## Done
<!-- 已完成的任务 -->
""")

# 从队列中获取下一个任务
def get_next_task_from_queue():
    queue_file = get_task_data_dir() / 'QUEUE.md'
    content = queue_file.read_text()

    # 解析 Ready 部分
    # 返回第一个任务
    # ...

# 更新队列状态
def update_queue_task(task_id, from_section, to_section):
    # 移动任务到新部分
    # ...
```

---

## 五、立即执行的优化

### 1. 修复状态不一致

```python
# 修复 JJC-20260421-002
# 添加缺失的 flow_log 条目
```

### 2. 清理 Cancelled 任务的 scheduler

```python
# 对所有 Cancelled 任务禁用 scheduler
for task in tasks:
    if task.get('state') == 'Cancelled':
        task.setdefault('_scheduler', {})['enabled'] = False
```

### 3. 添加 workflow 状态

```python
# 为活跃任务添加 _workflow 结构
```

### 4. 验证看板访问

```python
# 检查所有静态资源
# 测试 API 端点
# 验证前端加载
```

---

## 六、预期效果

### 短期（立即）
- ✅ 修复状态不一致
- ✅ 清理无用 scheduler
- ✅ 看板可正常访问

### 中期（1-2 周）
- 完整的 workflow 状态管理
- 规范的 agent 通信协议
- 任务队列机制

### 长期（1-2 月）
- 与 OpenClaw 原生 workflow 对齐
- 支持跨 agent 任务编排
- 可视化 workflow 进度
