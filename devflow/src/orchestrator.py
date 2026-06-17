"""
DevFlow 核心编排引擎
自动推进流水线，最小化人工介入
"""

import json
import time
import subprocess
import sys
from pathlib import Path
from typing import Optional

# 添加当前目录到路径
sys.path.insert(0, str(Path(__file__).parent.parent))
from src.state import ProjectState, Phase, PhasePromptBuilder


class DevFlowOrchestrator:
    """DevFlow 编排引擎 - 自动化开发流水线"""

    def __init__(self, project_dir: str, config: dict = None):
        self.project_dir = Path(project_dir)
        self.state = ProjectState(str(project_dir))
        self.config = config or self._load_config()
        self.max_fix_rounds = self.config.get("max_fix_rounds", 5)

    def _load_config(self) -> dict:
        """加载配置"""
        config_file = Path(__file__).parent.parent / "config" / "default.yaml"
        if config_file.exists():
            import yaml
            with open(config_file) as f:
                return yaml.safe_load(f)
        return {"max_fix_rounds": 5, "auto_approve_architecture": True}

    def run(self, requirements: str, project_name: str = "devflow-project"):
        """启动完整流水线"""
        # 初始化项目
        state = self.state.load()
        state["project_name"] = project_name
        state["requirements"] = requirements
        self.state.save(state)

        self._log(f"🚀 DevFlow 启动: {project_name}")
        self._log(f"📋 需求: {requirements[:100]}...")

        # Phase 1: 设计
        self._run_design(requirements)

        # Phase 2: 架构
        self._run_architecture()

        # Phase 3: 实现（并行）
        self._run_implementation()

        # Phase 4: 测试 + 纠错
        self._run_testing_with_fixes()

        # Phase 5: 审查
        self._run_review()

        # Phase 6: 交付
        self._run_delivery()

        self._log("✅ DevFlow 完成!")

    def _run_design(self, requirements: str):
        """Phase 1: 需求分析"""
        self._log("📝 Phase 1: 需求分析...")
        self.state.advance_phase(Phase.DESIGN)

        prefs = self.config.get("preferences", {})
        prompt = PhasePromptBuilder.design_prompt(requirements, prefs)

        design = self._call_agent(prompt)
        self._write_file("design.md", design)

        state = self.state.load()
        state["design"] = design
        self.state.save(state)
        self._log("✅ 设计完成")

    def _run_architecture(self):
        """Phase 2: 架构设计"""
        self._log("🏗️ Phase 2: 架构设计...")
        self.state.advance_phase(Phase.ARCHITECTURE)

        state = self.state.load()
        prefs = self.config.get("preferences", {})
        prompt = PhasePromptBuilder.architecture_prompt(state["design"], prefs)

        architecture = self._call_agent(prompt)
        self._write_file("architecture.md", architecture)

        # 解析模块列表
        modules = self._parse_modules(architecture)
        state["architecture"] = architecture
        for mod in modules:
            state["modules"][mod] = {"status": "pending", "spec": ""}
        self.state.save(state)

        # 自动审批或等待人工审批
        if not self.config.get("auto_approve_architecture", True):
            self._wait_for_approval("架构设计")

        self._log(f"✅ 架构完成，发现 {len(modules)} 个模块")

    def _run_implementation(self):
        """Phase 3: 代码实现"""
        self._log("💻 Phase 3: 代码实现...")
        self.state.advance_phase(Phase.IMPLEMENTATION)

        state = self.state.load()
        arch = state["architecture"]

        for module_name, module_info in state["modules"].items():
            if module_info["status"] == "completed":
                continue

            self._log(f"  📦 实现模块: {module_name}")
            self.state.update_module(module_name, "implementing")

            prompt = PhasePromptBuilder.implementation_prompt(
                arch, module_name, module_info.get("spec", "")
            )
            code = self._call_agent(prompt)

            # 保存代码文件
            code_clean = self._extract_code(code)
            ext = self._get_extension()
            code_path = self.project_dir / "src" / f"{module_name}{ext}"
            code_path.write_text(code_clean, encoding="utf-8")

            self.state.update_module(module_name, "implemented", file=str(code_path))
            self._log(f"  ✅ {module_name} 实现完成")

        self._log("✅ 全部模块实现完成")

    def _run_testing_with_fixes(self):
        """Phase 4: 测试 + 自动纠错"""
        self._log("🧪 Phase 4: 测试验证...")
        self.state.advance_phase(Phase.TESTING)

        state = self.state.load()
        for module_name, module_info in state["modules"].items():
            if module_info["status"] != "implemented":
                continue

            success = self._test_module_with_fix(module_name)
            if success:
                self.state.update_module(module_name, "tested")
            else:
                self.state.update_module(module_name, "failed")
                self.state.add_blocked_reason(
                    f"模块 {module_name} 测试失败，已用尽 {self.max_fix_rounds} 次修复机会",
                    module_name,
                )

        self._log("✅ 测试完成")

    def _test_module_with_fix(self, module_name: str) -> bool:
        """测试单个模块，失败自动修复"""
        state = self.state.load()
        code_path = self.project_dir / "src" / f"{module_name}{self._get_extension()}"
        code = code_path.read_text(encoding="utf-8")

        # 生成测试
        test_prompt = PhasePromptBuilder.test_prompt(code, module_name)
        test_code = self._call_agent(test_prompt)
        test_clean = self._extract_code(test_code)
        test_path = self.project_dir / "tests" / f"test_{module_name}.py"
        test_path.write_text(test_clean, encoding="utf-8")

        # 纠错循环
        for round_num in range(1, self.max_fix_rounds + 1):
            self._log(f"  🧪 测试 {module_name} (第 {round_num} 轮)...")

            # 运行测试
            test_result = self._run_pytest(test_path)

            if test_result["success"]:
                self._log(f"  ✅ {module_name} 测试通过")
                self.state.record_fix_attempt(module_name, True)
                return True

            # 失败，尝试修复
            self._log(f"  ❌ 测试失败，尝试修复...")
            self.state.record_fix_attempt(
                module_name, False, test_result.get("error", "")
            )

            fix_prompt = PhasePromptBuilder.fix_prompt(
                code, test_result.get("error", ""), test_result.get("output", ""), round_num
            )
            fixed_code = self._call_agent(fix_prompt)
            fixed_clean = self._extract_code(fixed_code)

            # 保存修复后的代码
            code_path.write_text(fixed_clean, encoding="utf-8")
            code = fixed_clean

            # 更新测试文件（可能也需要调整）
            test_prompt = PhasePromptBuilder.test_prompt(code, module_name)
            test_code = self._call_agent(test_prompt)
            test_clean = self._extract_code(test_code)
            test_path.write_text(test_clean, encoding="utf-8")

        self._log(f"  ⚠️ {module_name} 修复 {self.max_fix_rounds} 轮后仍失败")
        return False

    def _run_review(self):
        """Phase 5: 代码审查"""
        self._log("🔍 Phase 5: 代码审查...")
        self.state.advance_phase(Phase.REVIEW)

        review_results = []
        state = self.state.load()

        for module_name in state["modules"]:
            code_file = self.project_dir / "src" / f"{module_name}{self._get_extension()}"
            test_file = self.project_dir / "tests" / f"test_{module_name}.py"

            if not code_file.exists():
                continue

            code = code_file.read_text(encoding="utf-8")
            tests = test_file.read_text(encoding="utf-8") if test_file.exists() else ""
            test_results = self._run_pytest(test_file) if test_file.exists() else {}

            prompt = PhasePromptBuilder.review_prompt(
                code, tests, json.dumps(test_results, ensure_ascii=False)
            )
            review = self._call_agent(prompt)
            review_results.append({"module": module_name, "review": review})

        # 保存审查报告
        review_md = "# 代码审查报告\n\n"
        for r in review_results:
            review_md += f"## {r['module']}\n\n{r['review']}\n\n"
        self._write_file("review.md", review_md)

        state = self.state.load()
        state["review_notes"] = review_results
        self.state.save(state)
        self._log("✅ 审查完成")

    def _run_delivery(self):
        """Phase 6: 交付打包"""
        self._log("📦 Phase 6: 交付打包...")
        self.state.advance_phase(Phase.DELIVERY)

        state = self.state.load()

        # 生成项目总结
        summary = f"# {state['project_name']}\n\n"
        summary += f"## 需求\n{state['requirements']}\n\n"
        summary += f"## 模块\n"
        for name, info in state["modules"].items():
            status = "✅" if info["status"] == "tested" else "⚠️"
            summary += f"- {status} {name}: {info['status']}\n"
        summary += f"\n## 指标\n"
        summary += f"- 修复尝试: {state['metrics']['fix_attempts']}\n"
        summary += f"- 阻塞问题: {len(state['blocked_reasons'])}\n"

        self._write_file("README.md", summary)

        # 最终状态
        state["phase"] = Phase.COMPLETED
        self.state.save(state)
        self._log("✅ 交付完成!")

    # === 工具方法 ===

    def _call_agent(self, prompt: str, timeout: int = 300) -> str:
        """调用 AI agent（通过 OpenClaw 或直接 API）"""
        # 优先通过 OpenClaw 子 agent
        try:
            return self._call_openclaw_agent(prompt, timeout)
        except Exception:
            # fallback: 直接调用 OpenAI API
            return self._call_openai_api(prompt, timeout)

    def _call_openclaw_agent(self, prompt: str, timeout: int) -> str:
        """通过 OpenClaw 子 agent 调用"""
        import os
        api_key = os.environ.get("OPENAI_API_KEY") or os.environ.get("OPENAI_API_BASE")
        if not api_key:
            raise RuntimeError("No API key")

        # 简化实现：直接用 requests 调用
        return self._call_openai_api(prompt, timeout)

    def _call_openai_api(self, prompt: str, timeout: int) -> str:
        """直接调用 OpenAI 兼容 API"""
        import os
        import requests

        api_key = os.environ.get("OPENAI_API_KEY", "")
        api_base = os.environ.get("OPENAI_API_BASE", "https://api.openai.com/v1")
        model = os.environ.get("DEVFLOW_MODEL", "gpt-4o")

        if not api_key:
            return f"# Mock response for prompt: {prompt[:50]}..."

        headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
        data = {
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.3,
            "max_tokens": 4096,
        }

        try:
            resp = requests.post(
                f"{api_base}/chat/completions",
                headers=headers,
                json=data,
                timeout=timeout,
            )
            resp.raise_for_status()
            return resp.json()["choices"][0]["message"]["content"]
        except Exception as e:
            return f"# Error calling API: {e}"

    def _run_pytest(self, test_file: Path) -> dict:
        """运行 pytest"""
        try:
            result = subprocess.run(
                [sys.executable, "-m", "pytest", str(test_file), "-v", "--tb=short"],
                capture_output=True,
                text=True,
                timeout=120,
                cwd=str(self.project_dir),
            )
            return {
                "success": result.returncode == 0,
                "output": result.stdout + result.stderr,
                "error": result.stderr if result.returncode != 0 else "",
            }
        except subprocess.TimeoutExpired:
            return {"success": False, "output": "", "error": "Test timed out"}
        except Exception as e:
            return {"success": False, "output": "", "error": str(e)}

    def _parse_modules(self, architecture: str) -> list:
        """从架构文档中解析模块列表"""
        modules = []
        for line in architecture.split("\n"):
            if line.strip().startswith("- ") or line.strip().startswith("* "):
                mod = line.strip().lstrip("-* ").split(":")[0].strip()
                if mod and len(mod) < 50 and not mod.startswith("#"):
                    modules.append(mod.lower().replace(" ", "_").replace("-", "_"))
        if not modules:
            modules = ["core", "utils", "main"]
        return list(set(modules))

    def _extract_code(self, text: str) -> str:
        """从 markdown 代码块中提取代码"""
        if "```python" in text:
            start = text.index("```python") + 9
            end = text.index("```", start)
            return text[start:end].strip()
        elif "```" in text:
            start = text.index("```") + 3
            end = text.index("```", start)
            return text[start:end].strip()
        return text

    def _get_extension(self) -> str:
        """获取代码文件扩展名"""
        lang = self.config.get("project", {}).get("language", "python")
        extensions = {"python": ".py", "javascript": ".js", "typescript": ".ts", "go": ".go", "rust": ".rs"}
        return extensions.get(lang, ".py")

    def _write_file(self, filename: str, content: str):
        """写入文件"""
        filepath = self.project_dir / "docs" / filename
        filepath.parent.mkdir(parents=True, exist_ok=True)
        filepath.write_text(content, encoding="utf-8")

    def _log(self, message: str):
        """日志输出"""
        timestamp = time.strftime("%H:%M:%S")
        print(f"[{timestamp}] {message}")

        # 同时写入日志文件
        log_file = self.project_dir / "logs" / "devflow.log"
        log_file.parent.mkdir(parents=True, exist_ok=True)
        with open(log_file, "a") as f:
            f.write(f"[{timestamp}] {message}\n")

    def _wait_for_approval(self, item: str):
        """等待人工审批"""
        self._log(f"⏸️ 等待人工审批: {item}")
        state = self.state.load()
        state["waiting_for"] = item
        self.state.save(state)
        # 实际实现中，这里会等待通知回复
        input(f"请审批 {item} 后按回车继续...")
        state = self.state.load()
        state.pop("waiting_for", None)
        self.state.save(state)
        self._log(f"✅ {item} 已审批")


def main():
    """命令行入口"""
    import argparse

    parser = argparse.ArgumentParser(description="DevFlow - AI 开发流水线")
    parser.add_argument("requirements", help="项目需求描述")
    parser.add_argument("--name", default="devflow-project", help="项目名称")
    parser.add_argument("--dir", default="./project", help="项目目录")
    parser.add_argument("--config", help="配置文件路径")
    args = parser.parse_args()

    config = {}
    if args.config:
        import yaml
        with open(args.config) as f:
            config = yaml.safe_load(f)

    orchestrator = DevFlowOrchestrator(args.dir, config)
    orchestrator.run(args.requirements, args.name)


if __name__ == "__main__":
    main()
