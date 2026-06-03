"""
DevFlow 状态持久化模块
解决上下文爆炸问题：所有状态写文件，agent 之间通过文件传递信息
"""

import json
import os
import time
from pathlib import Path
from typing import Any, Optional
from enum import Enum


class Phase(str, Enum):
    INIT = "init"
    DESIGN = "design"
    ARCHITECTURE = "architecture"
    IMPLEMENTATION = "implementation"
    TESTING = "testing"
    REVIEW = "review"
    DELIVERY = "delivery"
    BLOCKED = "blocked"
    COMPLETED = "completed"
    FAILED = "failed"


class ProjectState:
    """项目状态管理器"""

    def __init__(self, project_dir: str):
        self.project_dir = Path(project_dir)
        self.state_file = self.project_dir / "state.json"
        self._ensure_dir()

    def _ensure_dir(self):
        """确保项目目录结构存在"""
        dirs = [
            self.project_dir,
            self.project_dir / "src",
            self.project_dir / "tests",
            self.project_dir / "logs",
            self.project_dir / "dist",
            self.project_dir / "docs",
        ]
        for d in dirs:
            d.mkdir(parents=True, exist_ok=True)

    def load(self) -> dict:
        """加载当前状态"""
        if self.state_file.exists():
            with open(self.state_file) as f:
                return json.load(f)
        return self._initial_state()

    def save(self, state: dict):
        """保存状态"""
        state["updated_at"] = time.time()
        with open(self.state_file, "w") as f:
            json.dump(state, f, indent=2, ensure_ascii=False)

    def _initial_state(self) -> dict:
        return {
            "project_name": "",
            "phase": Phase.INIT,
            "created_at": time.time(),
            "updated_at": time.time(),
            "requirements": "",
            "design": "",
            "architecture": "",
            "modules": {},
            "test_results": {},
            "review_notes": [],
            "blocked_reasons": [],
            "completed_phases": [],
            "fix_rounds": {},
            "metrics": {
                "total_files": 0,
                "total_lines": 0,
                "tests_passed": 0,
                "tests_failed": 0,
                "fix_attempts": 0,
            },
        }

    def advance_phase(self, new_phase: Phase, reason: str = ""):
        """推进到下一阶段"""
        state = self.load()
        state["completed_phases"].append(
            {
                "phase": state["phase"],
                "completed_at": time.time(),
                "reason": reason,
            }
        )
        state["phase"] = new_phase
        self.save(state)

    def add_blocked_reason(self, reason: str, module: str = ""):
        """记录阻塞原因"""
        state = self.load()
        state["blocked_reasons"].append(
            {
                "reason": reason,
                "module": module,
                "timestamp": time.time(),
                "phase": state["phase"],
            }
        )
        state["phase"] = Phase.BLOCKED
        self.save(state)

    def record_fix_attempt(self, module: str, success: bool, error: str = ""):
        """记录修复尝试"""
        state = self.load()
        if module not in state["fix_rounds"]:
            state["fix_rounds"][module] = []
        state["fix_rounds"][module].append(
            {
                "success": success,
                "error": error,
                "timestamp": time.time(),
            }
        )
        state["metrics"]["fix_attempts"] += 1
        self.save(state)

    def update_module(self, module_name: str, status: str, **kwargs):
        """更新模块状态"""
        state = self.load()
        if module_name not in state["modules"]:
            state["modules"][module_name] = {}
        state["modules"][module_name].update({"status": status, "updated_at": time.time(), **kwargs})
        self.save(state)

    def get_pending_modules(self) -> list:
        """获取待处理的模块"""
        state = self.load()
        return [
            name
            for name, info in state["modules"].items()
            if info.get("status") in ("pending", "failed")
        ]

    def is_blocked(self) -> bool:
        return self.load()["phase"] == Phase.BLOCKED

    def get_summary(self) -> str:
        """获取可读的状态摘要（给 agent 用，不是给人看的）"""
        state = self.load()
        lines = [
            f"Project: {state['project_name']}",
            f"Phase: {state['phase']}",
            f"Modules: {len(state['modules'])}",
            f"Blocked: {len(state['blocked_reasons'])}",
            f"Fix attempts: {state['metrics']['fix_attempts']}",
            f"Tests: {state['metrics']['tests_passed']}P/{state['metrics']['tests_failed']}F",
        ]
        if state["blocked_reasons"]:
            latest = state["blocked_reasons"][-1]
            lines.append(f"Latest block: {latest['reason']}")
        return "\n".join(lines)


class PhasePromptBuilder:
    """阶段提示词构建器 - 每个阶段的完整指令"""

    @staticmethod
    def design_prompt(requirements: str, preferences: dict) -> str:
        return f"""你是一个需求分析师。根据以下需求输出设计文档。

需求: {requirements}

技术偏好:
{json.dumps(preferences, indent=2, ensure_ascii=False)}

输出要求:
1. 项目概述（一句话说明）
2. 功能列表（每个功能一句话）
3. 技术约束
4. 非功能需求（性能、安全等）
5. 模块划分（每个模块的职责）

直接输出 Markdown，不要解释。"""

    @staticmethod
    def architecture_prompt(design_doc: str, preferences: dict) -> str:
        return f"""你是一个架构师。根据设计文档输出技术架构。

设计文档:
{design_doc}

技术偏好:
{json.dumps(preferences, indent=2, ensure_ascii=False)}

输出要求:
1. 技术栈选择（带理由）
2. 项目结构（目录树）
3. 模块依赖关系
4. API 设计（如有）
5. 数据模型（如有）
6. 每个模块的实现要点

直接输出 Markdown，不要解释。"""

    @staticmethod
    def implementation_prompt(architecture: str, module_name: str, module_spec: str) -> str:
        return f"""你是一个开发工程师。根据架构文档实现指定模块。

架构文档:
{architecture}

要实现的模块: {module_name}
模块说明: {module_spec}

输出要求:
1. 完整的可运行代码
2. 必要的注释
3. 依赖声明（requirements.txt 或 pyproject.toml 片段）

规则:
- 代码必须完整，不要用 ... 或 # TODO
- 遵循 Python 最佳实践
- 使用 type hints
- 错误处理要完善

直接输出代码文件，用 ```python``` 包裹。"""

    @staticmethod
    def test_prompt(src_code: str, module_name: str) -> str:
        return f"""你是一个测试工程师。为以下代码编写测试。

源代码:
{src_code}

输出要求:
1. 使用 pytest
2. 覆盖核心功能
3. 包含正常和异常情况
4. 测试必须可以独立运行

直接输出测试代码，用 ```python``` 包裹。"""

    @staticmethod
    def fix_prompt(code: str, error: str, test_output: str, round_num: int) -> str:
        return f"""你是一个调试专家。代码测试失败，请修复。

当前代码:
{code}

错误信息:
{error}

测试输出:
{test_output}

这是第 {round_num} 次修复尝试。

输出要求:
1. 分析错误原因
2. 输出修复后的完整代码
3. 解释修复内容

直接输出修复后的代码，用 ```python``` 包裹。"""

    @staticmethod
    def review_prompt(code: str, tests: str, test_results: str) -> str:
        return f"""你是一个代码审查专家。审查以下代码。

代码:
{code}

测试:
{tests}

测试结果:
{test_results}

审查维度:
1. 代码质量（可读性、命名、结构）
2. 错误处理
3. 安全性
4. 性能
5. 测试覆盖

输出格式:
- 评分: X/10
- 问题列表: [严重/中等/轻微]
- 改进建议
- 总结: PASS 或 NEEDS_FIX"""
