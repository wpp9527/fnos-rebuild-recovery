# 国际大事日报重建实施计划

关联设计：`docs/superpowers/specs/2026-05-02-international-brief-design.md`

## 目标

以最小可运行闭环方式，重建一条完全不依赖 Edict 的 OpenClaw 原生日报链：
- 每天 08:00 生成过去 24 小时国际大事简讯
- 所有状态与产物写入 `state/intl-brief/`
- 内容生产链与飞书投递解耦
- 先跑通内容，再接飞书

## 实施阶段

### Phase 0 — 清理旧链影响面
目标：确保新链不会继续受旧 `daily-morning-brief` 干扰。

任务：
1. 审核现有 cron 中 `daily-morning-brief` 的保留策略
2. 将其标记为：
   - 停用；或
   - 改名为 legacy 并禁用
3. 在文档中注明：国际日报新链不依赖任何 `edict-*` 运行时

完成标准：
- 新链上线前，旧朝报链不会再制造误报警或重复推送

### Phase 1 — 建立目录与运行骨架
目标：建立稳定的文件布局与脚本入口。

任务：
1. 新建目录：
   - `scripts/intl-brief/`
   - `state/intl-brief/raw/`
   - `state/intl-brief/normalized/`
   - `state/intl-brief/briefs/`
   - `state/intl-brief/runs/`
2. 建立脚本骨架：
   - `fetch_sources.py`
   - `build_brief.py`
   - `render_brief.py`
   - `run_daily.sh`
3. 约定统一输入输出路径和日期参数格式

完成标准：
- 本地可执行骨架脚本
- 路径和命名固定，不再依赖历史目录

### Phase 2 — 固定样本驱动的核心规则实现
目标：先在无网络条件下跑通规则链。

任务：
1. 准备样本输入夹具：
   - 正常新闻日
   - 重大事件密集日
   - 低事件量日
   - 单源偏置日
2. 先写测试，再实现：
   - 去重
   - 多源归并
   - 分类
   - 重要性排序
   - 不确定性标签
   - 缩版逻辑
3. 输出标准化事件 JSON 与 markdown 成品

完成标准：
- 规则测试全绿
- 不依赖真实网络即可生成合格日报

### Phase 3 — 公开源采集器接入
目标：将固定公开源接入生产链。

任务：
1. 确定首版源列表（少量高质量源）
2. 实现采集器标准化输出
3. 对采集失败建立容错：
   - 超时
   - 403/429
   - 空结果
4. 把失败源/成功源写入 `runs/latest.json`

完成标准：
- 真实抓源可生成 `raw/YYYY-MM-DD.json`
- 部分源失败不阻断整条链

### Phase 4 — 成品渲染与运行留痕
目标：生成稳定可读的日报和机器可读状态文件。

任务：
1. 渲染 markdown 成品
2. 生成 `runs/latest.json`
3. 保证“新数据”与“旧产物”不会混淆
4. 增加运行摘要字段：
   - run_at
   - source_success_count
   - source_failure_count
   - candidate_count
   - top_story_count
   - category_counts
   - status
   - error_summary

完成标准：
- 生成 `briefs/YYYY-MM-DD.md`
- 失败时状态文件明确反映失败阶段

### Phase 5 — OpenClaw cron 接入
目标：让链路每日稳定自动运行。

任务：
1. 新增 OpenClaw cron job：08:00 Asia/Shanghai
2. `delivery.mode=none`
3. `sessionTarget=isolated`
4. payload 只调用新链 `run_daily.sh`
5. 禁止复用旧 Edict 晨报任务

完成标准：
- cron 可独立跑通，不依赖外部旧服务

### Phase 6 — 飞书投递适配
目标：在内容链稳定后接飞书。

任务：
1. 设计投递接口：读取 `briefs/YYYY-MM-DD.md`
2. 接入现有飞书渠道信息
3. 记录投递成功/失败回执
4. 保持“投递失败 != 内容生产失败”

完成标准：
- 可向目标飞书会话发送日报
- 投递状态单独留痕

## TDD 执行顺序

实现必须按下列顺序推进：
1. 先为纯规则层写 failing tests
2. 再实现最小代码使其通过
3. 再补真实采集器测试/样本回放测试
4. 最后再接 cron 和飞书

推荐测试落点：
- `tests/intl-brief/test_dedup_*.sh|py`
- `tests/intl-brief/test_classify_*.sh|py`
- `tests/intl-brief/test_render_*.sh|py`
- `tests/intl-brief/test_run_daily_*.sh|py`

## 风险与控制

### 风险 1：公开源不稳定
控制：
- 多源
- 容错
- 允许部分失败

### 风险 2：摘要质量波动
控制：
- 先做规则层约束
- 用固定样本回放回归

### 风险 3：旧链残留干扰
控制：
- 旧 `daily-morning-brief` 停用或标记 legacy
- 新链完全独立命名与目录

### 风险 4：推送问题污染主链状态
控制：
- 投递层后接
- 生产链和投递链分状态记录

## 验收顺序

1. 样本驱动规则测试通过
2. 真实抓源能生成日报
3. cron 自动执行成功
4. 飞书投递成功
5. 连续多天运行观察稳定

## 推荐第一批落地任务

1. 停用旧 `daily-morning-brief`
2. 建立 `scripts/intl-brief/` 与 `state/intl-brief/` 目录骨架
3. 编写第一批样本夹具
4. 从“去重 + 分类 + 渲染”开始做 TDD
5. 跑出第一份本地 markdown 日报

## 完成定义

当满足以下条件时，v1 视为完成：
- 已停用旧 Edict 朝报链
- 新链能在当前 workspace 内独立生成日报
- `runs/latest.json` 能正确反映状态
- 连续多次运行不依赖人工修补
- 飞书投递已能单独接入，不影响内容生产链稳定性
