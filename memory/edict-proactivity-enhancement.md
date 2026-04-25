# Edict Proactivity Enhancement

## 基于 Proactive-Agent-Skill + Agent-Team-Orchestration + Proactive-Tasks 的增强方案

---

## 一、WAL 协议集成

### 问题
当前 edict 在上下文压缩时会丢失关键状态，导致调度器误判。

### 解决方案
引入 WAL（Write-Ahead Logging）协议：

```python
# 在 kanban_update.py 中添加 WAL 支持
WAL_DIR = _ACTIVE_DATA_DIR / 'wal'
WAL_DIR.mkdir(exist_ok=True)

def wal_log(event_type, task_id, details):
    """写入 WAL 日志（原子操作）"""
    wal_file = WAL_DIR / f'WAL-{datetime.datetime.now().strftime("%Y-%m-%d")}.log'
    entry = {
        "ts": now_iso(),
        "event": event_type,
        "taskId": task_id,
        "details": details
    }
    with open(wal_file, 'a', encoding='utf-8') as f:
        f.write(json.dumps(entry, ensure_ascii=False) + '\n')

# 关键操作前先写 WAL
def cmd_dispatch(task_id, target_agent):
    wal_log('DISPATCH', task_id, {"target": target_agent})
    # ... 原有逻辑
```

---

## 二、SESSION-STATE.md 活跃工作内存

### 问题
调度器每次扫描都要重读大量任务，无法快速恢复当前状态。

### 解决方案
创建 SESSION-STATE.md 存储"当前正在做什么"：

```python
SESSION_STATE_FILE = _ACTIVE_DATA_DIR / 'SESSION-STATE.md'

def update_session_state(task_id, phase, agent, progress, next_action):
    """更新活跃工作内存"""
    content = f"""# Session State

## Current Task
- **ID:** {task_id}
- **Phase:** {phase}
- **Agent:** {agent}
- **Progress:** {progress}%

## Next Action
{next_action}

## Last Updated
{now_iso()}

## Danger Zone Log
<!-- 自动追加重要操作 -->
"""
    SESSION_STATE_FILE.write_text(content, encoding='utf-8')
```

---

## 三、工作缓冲区（Danger Zone Safety）

### 问题
上下文压缩时可能丢失最近的操作记录。

### 解决方案
创建 working-buffer.md 自动追加所有关键操作：

```python
WORKING_BUFFER_FILE = _ACTIVE_DATA_DIR / 'working-buffer.md'

def append_to_working_buffer(message):
    """追加到工作缓冲区"""
    ts = now_iso()
    with open(WORKING_BUFFER_FILE, 'a', encoding='utf-8') as f:
        f.write(f"- [{ts}] {message}\n")

# 在关键操作时调用
def cmd_done(task_id, summary):
    append_to_working_buffer(f"TASK_DONE: {task_id} - {summary}")
    # ... 原有逻辑
```

---

## 四、Agent 移交协议

### 问题
当前 edict 的 agent 间移交不够明确，缺少标准化的移交消息。

### 解决方案
基于 agent-team-orchestration 的移交协议：

```python
def create_handoff_message(from_agent, to_agent, task_id, artifacts, known_issues, next_action):
    """创建标准化的移交消息"""
    return f"""
## 移交通知

**从:** {from_agent}
**到:** {to_agent}
**任务:** {task_id}

### 已完成
- {artifacts}

### 已知问题
- {known_issues}

### 下一步
{next_action}

### 验证方式
```bash
python3 scripts/verify_handoff.py {task_id}
```
"""
```

---

## 五、任务生命周期明确化

### 当前状态
```
Inbox → Zhongshu → Menxia → Shangshu → Gongbu → Done
```

### 增强后
```
Inbox → Draft → Review → Assigned → In Progress → Review → Done | Cancelled | Blocked
```

每个状态转换都有：
1. **触发条件**
2. **负责 agent**
3. **产出物**
4. **验证标准**

```python
TASK_LIFECYCLE = {
    'Inbox': {
        'next': 'Draft',
        'agent': 'taizi',
        'trigger': 'user_request',
        'artifact': 'task_record',
        'validation': 'has_title_and_goal'
    },
    'Draft': {
        'next': 'Review',
        'agent': 'zhongshu',
        'trigger': 'dispatch_from_taizi',
        'artifact': 'draft_spec',
        'validation': 'has_spec_and_todos'
    },
    'Review': {
        'next': ['Assigned', 'Draft'],  # 可能退回
        'agent': 'menxia',
        'trigger': 'dispatch_from_zhongshu',
        'artifact': 'review_notes',
        'validation': 'has_approval_or_rejection'
    },
    # ...
}
```

---

## 六、立即实施

### Phase 1: 基础设施（今天完成）
- [x] 创建 WAL 目录和日志函数
- [x] 创建 SESSION-STATE.md 模板
- [x] 创建 working-buffer.md

### Phase 2: 核心集成（明天完成）
- [ ] 在 kanban_update.py 中集成 WAL
- [ ] 在 dashboard/server.py 中读取 SESSION-STATE.md
- [ ] 为每个 agent 创建标准化的移交消息

### Phase 3: 验证和测试（后天完成）
- [ ] 测试上下文压缩后的状态恢复
- [ ] 测试 agent 间移交
- [ ] 测试任务生命周期

---

## 七、预期效果

### 短期
- ✅ 状态恢复更快（读取 SESSION-STATE.md）
- ✅ 操作记录不会丢失（WAL + working-buffer）
- ✅ 移交更明确（标准化协议）

### 中期
- 任务生命周期可视化
- Agent 协作质量提升
- 调度器误判减少

### 长期
- 完全自主的任务推进
- 自适应的任务优先级
- 持续改进的协作模式
