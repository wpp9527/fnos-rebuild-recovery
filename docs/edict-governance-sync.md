# edict-governance 同步规则

## 目的

把本地工作树 `/opt/fnos-media/services/edict-localized/repo` 持续同步到 GitHub 新仓：

- `git@github.com:wpp9527/edict-governance.git`

当前采用的是：

- **干净快照仓路线**
- 不复用原仓历史对象链
- 以当前工作树为准，导出后推送到新仓

---

## 为什么这么做

原始仓库历史对象链在直接推送到新 GitHub 仓时被远端拒绝，表现为 remote unpack / index-pack 失败。

因此当前更稳的方案是：

1. 从源目录导出当前工作树
2. 排除 `.git`、`node_modules`、`dist` 等重资产/派生产物
3. 在独立导出目录维护一个干净 Git 仓
4. 持续把快照推送到 GitHub

---

## 当前同步脚本

路径：

- `/opt/fnos-media/services/openclaw/home/.openclaw/workspace/tools/sync-edict-governance.sh`

源目录：

- `/opt/fnos-media/services/edict-localized/repo`

导出目录：

- `/tmp/edict-governance-export`

远程仓库：

- `git@github.com:wpp9527/edict-governance.git`

---

## 使用方式

执行：

```bash
/opt/fnos-media/services/openclaw/home/.openclaw/workspace/tools/sync-edict-governance.sh
```

脚本会：

1. 从源目录同步文件到导出目录
2. 自动排除 `.git` / `node_modules` / `dist` / `__pycache__` / `.pytest_cache`
3. 在导出目录执行 `git add .`
4. 若有变更，自动提交
5. 自动推送到 GitHub `main`

---

## 当前身份配置

- GitHub 用户名：`wpp9527`
- Git 邮箱：`wangpengpeng9527@gmail.com`
- GitHub SSH：已打通

---

## 适用场景

适合：

- 快速备份当前工作树
- 持续把本地最新状态推到 GitHub
- 避免原仓历史问题影响备份仓

不适合：

- 保留原始仓完整提交历史
- 做严格的上游 fork / rebase / cherry-pick 工作流

---

## 后续建议

如果后面需要更正式的双仓治理，可以再加：

1. README 与仓库说明
2. 定时同步 cron
3. 明确哪些目录应永久排除
4. 需要时再做“原仓历史修复/迁移”专项
