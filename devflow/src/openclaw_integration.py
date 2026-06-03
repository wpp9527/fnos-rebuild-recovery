"""
DevFlow OpenClaw 集成模块
将 DevFlow 编排引擎接入 OpenClaw 的 Cron / sessions_spawn 体系
"""

import json
import time
from pathlib import Path
from typing import Optional


def generate_cron_job(
    project_name: str,
    requirements: str,
    project_dir: str,
    model: str = None,
    timeout: int = 7200,
) -> dict:
    """
    生成 OpenClaw Cron Job 配置
    这是"启动一次，自动跑完"的关键
    """
    prompt = f"""你是 DevFlow 自动开发流水线的执行者。

项目名称: {project_name}
项目目录: {project_dir}
需求: {requirements}

你的任务是执行以下步骤，每步完成后自动进入下一步：

1. 读取 {project_dir}/state.json 了解当前进度
2. 根据当前 phase 执行对应任务
3. 执行结果写入对应文件
4. 更新 state.json 中的 phase
5. 如果测试失败，自动修复并重试（最多5轮）
6. 完成后输出总结

关键规则：
- 不要停下来问人，自己决策
- 遇到错误先尝试修复
- 所有状态写文件，不依赖上下文
- 完成后输出 "DEVFLOW_COMPLETE" + 总结

开始执行。"""

    job = {
        "name": f"devflow-{project_name}",
        "schedule": {"kind": "at", "at": "now"},  # 立即执行
        "payload": {
            "kind": "agentTurn",
            "message": prompt,
            "timeoutSeconds": timeout,
        },
        "sessionTarget": "isolated",
        "delivery": {"mode": "announce"},
        "enabled": True,
    }

    if model:
        job["payload"]["model"] = model

    return job


def generate_monitoring_prompt(project_dir: str) -> str:
    """生成监控提示词（用于 Cron 定时检查进度）"""
    return f"""你是 DevFlow 的监控 agent。检查项目进度并汇报。

执行以下操作：
1. 读取 {project_dir}/state.json
2. 检查当前 phase 和是否有 blocked
3. 如果 blocked，尝试分析原因并给出建议
4. 如果已完成，汇报最终结果
5. 如果超时（>2小时未更新），记录警告

输出格式：
- 项目名: xxx
- 当前阶段: xxx
- 进度: X%
- 状态: 正常/阻塞/完成
- 建议: xxx

只在以下情况输出非摘要信息：
- 项目完成
- 遇到真正阻塞
- 超时警告"""


def init_project(project_dir: str, requirements: str, project_name: str) -> str:
    """初始化项目（在 OpenClaw workspace 中）"""
    from src.state import ProjectState

    state = ProjectState(project_dir)
    initial = state._initial_state()
    initial["project_name"] = project_name
    initial["requirements"] = requirements
    state.save(initial)

    return f"项目已初始化: {project_dir}"


def get_project_status(project_dir: str) -> dict:
    """获取项目状态（供 OpenClaw 查询）"""
    state_file = Path(project_dir) / "state.json"
    if not state_file.exists():
        return {"error": "项目不存在"}
    with open(state_file) as f:
        return json.load(f)


def generate_openclaw_cron_commands(
    project_dir: str, project_name: str, requirements: str
) -> list:
    """
    生成可直接在 OpenClaw 中执行的 cron 命令
    返回需要手动执行的步骤
    """
    steps = []

    steps.append(
        {
            "step": 1,
            "action": "初始化项目",
            "command": f"""在 OpenClaw 主 session 中运行：
```
exec: mkdir -p {project_dir}/{{src,tests,logs,dist,docs}}
```
然后用 write 工具创建 {project_dir}/state.json""",
        }
    )

    steps.append(
        {
            "step": 2,
            "action": "创建 Cron Job",
            "command": f"""使用 cron(action=add) 创建任务：
- name: devflow-{project_name}
- schedule: {{kind: "at", at: "now"}}
- payload.kind: agentTurn
- payload.message: 见下方完整 prompt
- payload.timeoutSeconds: 7200
- sessionTarget: isolated
- delivery.mode: announce""",
        }
    )

    steps.append(
        {
            "step": 3,
            "action": "监控进度",
            "command": f"""可选：创建监控 Cron Job
- schedule: {{kind: "every", everyMs: 1800000}}  # 每30分钟
- 检查 {project_dir}/state.json
- 汇报进度""",
        }
    )

    return steps
