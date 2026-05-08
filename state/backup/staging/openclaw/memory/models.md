# 🤖 模型配置

## Provider 清单

| Provider | Base URL | 模型 |
|----------|----------|------|
| cpa | https://cpi.19930901.xyz:5000/v1 | gpt-5.5, gpt-5.4, deepseek-v4-pro, minimax-m2.7 |
| baidu | https://qianfan.baidubce.com/v2/coding | glm-5.1 |
| qtcool | https://gpt.qt.cool/v1 | deepseek-v4-flash |
| ollama | http://127.0.0.1:11434/v1 | qwen3:4b, qwen3-embedding:0.6b |

## 模型状态（2026-05-08 测试）

| 模型 | 状态 | 备注 |
|------|------|------|
| cpa/deepseek-v4-pro | ✅ | 自称 Claude（CPA 网关接入），3s |
| cpa/minimax-m2.7 | ✅ | 自称 MiniMax-M2，4s |
| baidu/glm-5.1 | ✅ | 3s，当前 fallback |
| qtcool/deepseek-v4-flash | ✅ | 5s |
| cpa/gpt-5.5 | ⚠️ 限流 | 主力模型，常被限流 |
| cpa/gpt-5.4 | ⚠️ 限流 | 同 CPA 额度 |
| ollama/qwen3:4b | ⚠️ 慢 | 25s/简单问题，负载高时超时 |
| ollama/qwen3-embedding:0.6b | ❌ | 嵌入模型，不支持对话 |

## 默认模型策略

- Primary: cpa/gpt-5.5
- Fallbacks: baidu/glm-5.1 → cpa/deepseek-v4-pro
