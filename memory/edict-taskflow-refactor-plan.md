# Edict TaskFlow 重构方案

## 目标
将当前 edict 系统从"多文件 + 多状态字段"模式升级为"TaskFlow 兼容的单一真源模式"。

---

## 核心改进

### 1. 统一状态包 (stateJson)

**现状**：
```json
{
  "state": "Assigned",
  "org": "尚书省",
  "now": "当前进展",
  "flow_log": [...],
  "todos": [...],
  "scheduler": {...},
  "output": "...",
  ...
}
```

**改进后**：
```json
{
  "state": "Assigned",
  "org": "尚书省",
  "now": "当前进展",
  "_flow": {
    "flowId": "edict:JJC-20260421-002",
    "revision": 5,
    "currentStep": "shangshu-dispatch",
    "stateJson": {
      "goal": "轻量完整闭环实跑验证",
      "completedSteps": ["taizi-create", "zhongshu-draft", "menxia-review"],
      "waitingFor": null,
      "artifacts": {
        "draft": "/path/to/draft.md",
        "reviewNotes": "/path/to/notes.md"
      }
    },
    "waitJson": null,
    "linkedTasks": ["subtask-1", "subtask-2"],
    "ownerSession": "agent:taizi:main"
  },
  "flow_log": [...],
  ...
}
```

**好处**：
- 单一位置存储所有可恢复状态
- 明确的 revision 跟踪
- 清晰的 owner session
- 子任务链接

---

### 2. 等待状态明确化

**现状问题**：
调度器认为所有"停滞"都需要重试，不理解"等待"。

**改进**：
```python
# 在 scheduler 中新增等待类型判断
WAIT_REASONS = {
    'external_reply': '等待外部回复',
    'human_approval': '等待人工审批',
    'dependency': '等待依赖任务完成',
    'resource': '等待资源就绪',
}

# 修改 handle_scheduler_scan
if sched.get('waitJson'):
    wait_kind = sched['waitJson'].get('kind')
    if wait_kind in WAIT_REASONS:
        # 不触发重试，只是提醒
        continue
```

---

### 3. 修订检查机制

**现状问题**：
`kanban_update.py` 用文件锁，但 dashboard 的 `save_tasks` 没有。

**改进**：
```python
def save_tasks_with_revision(tasks, expected_revision=None):
    """带修订检查的保存"""
    current_revision = get_current_revision()
    if expected_revision is not None and current_revision != expected_revision:
        raise RevisionConflictError(f"Revision mismatch: expected {expected_revision}, got {current_revision}")
    
    # 原子写入
    atomic_json_write(TASKS_FILE, tasks)
    
    # 更新 revision
    increment_revision()
```

---

### 4. 任务链接

**现状问题**：
子任务和父任务之间没有明确链接。

**改进**：
```python
def cmd_delegate(task_id, subtask_id, subtask_type, agent_id):
    """创建委托子任务并链接到父任务"""
    # 创建子任务
    subtask = {
        "id": subtask_id,
        "parentId": task_id,
        "type": subtask_type,
        "state": "Pending",
        ...
    }
    
    # 在父任务中记录链接
    def modifier(tasks):
        parent = find_task(tasks, task_id)
        if parent:
            parent.setdefault('childTasks', []).append(subtask_id)
            parent['_flow']['linkedTasks'] = parent['_flow'].get('linkedTasks', []) + [subtask_id]
        return tasks
    
    atomic_json_update(TASKS_FILE, modifier, [])
```

---

### 5. 单一数据源保证

**现状问题**：
`repo/data` 和 `workspace-main/data` 同时存在。

**改进**：
```python
# 在所有脚本开头强制检查
def ensure_single_source():
    canonical = get_canonical_data_dir()
    legacy = get_legacy_data_dir()
    
    if legacy.exists() and canonical != legacy:
        # 检查是否有新数据在 legacy
        if has_recent_data(legacy):
            log.warning(f"⚠️ Legacy data directory still has recent data: {legacy}")
            log.warning(f"   Consider migrating to canonical: {canonical}")
        
        # 强制使用 canonical
        os.environ['EDICT_TASK_DATA_DIR'] = str(canonical)
        return canonical
    
    return canonical
```

---

## 实施优先级

### Phase 1: 立即修复（已完成）
- [x] 数据源统一
- [x] 调度器 flow_log 检查
- [x] cmd_done 的 scheduler 状态更新

### Phase 2: 短期优化（建议 1-2 天内完成）
- [ ] 添加 `_flow` 结构到所有新任务
- [ ] 实现 revision 检查机制
- [ ] 迁移 `repo/data` 历史数据

### Phase 3: 中期重构（建议 1-2 周内完成）
- [ ] 完整的 TaskFlow runtime 集成
- [ ] 子任务链接和生命周期管理
- [ ] 等待状态明确化

### Phase 4: 长期演进
- [ ] 与 OpenClaw 原生 TaskFlow runtime 对齐
- [ ] 支持跨 agent 的任务编排
- [ ] 插件化的状态转换规则

---

## 兼容性保证

所有改进都应该：
1. 向后兼容现有任务格式
2. 新字段使用 `_` 前缀（如 `_flow`）
3. 不破坏现有的 `kanban_update.py` 调用
4. 提供迁移脚本而非强制升级

---

## 预期效果

实施后应该能解决：
- ✅ 看板前后台不一致（单一真源）
- ✅ 任务完成后仍被调度（等待状态明确）
- ✅ 并发修改冲突（revision 检查）
- ✅ 任务状态难以追踪（统一 stateJson）
- ✅ 子任务无链接（任务链接机制）
