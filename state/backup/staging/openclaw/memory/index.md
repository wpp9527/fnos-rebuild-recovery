# 📑 记忆索引

> 太子的记忆导航，按主题分类

## 主题文件

| 文件 | 内容 | 更新频率 |
|------|------|----------|
| [network.md](network.md) | 网络拓扑、设备、端口、域名 | 架构变更时 |
| [services.md](services.md) | 服务清单、配置路径、Docker | 配置变更时 |
| [models.md](models.md) | 模型配置、测试状态、限流情况 | 测试/调整时 |
| [credentials.md](credentials.md) | 账号密码 Token（敏感） | 凭证变更时 |
| [github.md](github.md) | 仓库清单、项目状态 | 仓库变更时 |
| [lessons.md](lessons.md) | 踩坑记录、经验教训 | 每次踩坑时 |
| [daily/](daily/) | 每日操作日志 | 每次会话 |

## 维护规则

1. **MEMORY.md** 只做索引导航，不存详细内容
2. 敏感信息统一放 **credentials.md**
3. 每次会话结束更新对应主题文件 + daily log
4. 每周整理 daily/ → 提炼到 lessons.md，清理 7 天前日志
5. 每月审阅索引，清理过时信息
