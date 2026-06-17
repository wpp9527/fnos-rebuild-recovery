#!/usr/bin/env python3
"""
DevFlow - 一键启动 AI 开发流水线

用法:
  python run.py "你的需求描述" --name 项目名
  
最小介入流程:
  1. 你输入一句话需求
  2. 自动完成设计→架构→实现→测试→审查
  3. 完成后通知你
"""

import argparse
import sys
from pathlib import Path

# 确保导入路径正确
sys.path.insert(0, str(Path(__file__).parent))

from src.orchestrator import DevFlowOrchestrator
from src.openclaw_integration import generate_cron_job, init_project


def main():
    parser = argparse.ArgumentParser(
        description="DevFlow - 最小人工介入的 AI 开发流水线",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python run.py "开发一个 Flask REST API，支持用户 CRUD 操作"
  python run.py "写一个 Python 爬虫，抓取豆瓣电影 Top250" --name douban-scraper
  python run.py "开发一个简单的博客系统" --config custom_config.yaml
        """,
    )
    parser.add_argument("requirements", help="项目需求（一句话描述）")
    parser.add_argument("--name", default="my-project", help="项目名称")
    parser.add_argument("--dir", default=None, help="项目目录（默认: ./projects/{name}）")
    parser.add_argument("--config", default=None, help="配置文件路径")
    parser.add_argument("--model", default=None, help="AI 模型（如 gpt-4o）")
    parser.add_argument("--cron", action="store_true", help="输出 Cron Job 配置而非直接执行")
    parser.add_argument("--status", default=None, help="查询项目状态")

    args = parser.parse_args()

    # 查询状态
    if args.status:
        from src.openclaw_integration import get_project_status
        status = get_project_status(args.status)
        print(json.dumps(status, indent=2, ensure_ascii=False))
        return

    # 确定项目目录
    project_dir = args.dir or f"./projects/{args.name}"

    # Cron 模式：输出配置
    if args.cron:
        import json
        job = generate_cron_job(args.name, args.requirements, project_dir, args.model)
        print(json.dumps(job, indent=2, ensure_ascii=False))
        print("\n# 将以上 JSON 传递给 cron(action=add) 即可启动")
        return

    # 直接执行模式
    print("=" * 60)
    print("🚀 DevFlow - AI 开发流水线")
    print("=" * 60)
    print(f"项目: {args.name}")
    print(f"需求: {args.requirements}")
    print(f"目录: {project_dir}")
    print("=" * 60)

    # 加载配置
    config = {}
    if args.config:
        import yaml
        with open(args.config) as f:
            config = yaml.safe_load(f)
    else:
        config_file = Path(__file__).parent / "config" / "default.yaml"
        if config_file.exists():
            import yaml
            with open(config_file) as f:
                config = yaml.safe_load(f)

    if args.model:
        config.setdefault("agents", {})["default_model"] = args.model

    # 启动流水线
    orchestrator = DevFlowOrchestrator(project_dir, config)

    try:
        orchestrator.run(args.requirements, args.name)
    except KeyboardInterrupt:
        print("\n⚠️ 流水线已中断，状态已保存。可随时恢复。")
    except Exception as e:
        print(f"\n❌ 错误: {e}")
        print("状态已保存，可查看 state.json 了解进度")


import json  # 确保顶层导入
if __name__ == "__main__":
    main()
