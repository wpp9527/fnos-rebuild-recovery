# DNF 后台管理系统 - 功能扩展建议

## 一、数据查询类功能

### 1. 角色详情查询
- **数据源**: `taiwan_cain.charac_info`
- **功能**: 查询角色属性、装备、技能、疲劳值
- **API**: `/api/v1/character/:id/detail`
- **自检**: 对比游戏内实际数据

### 2. 物品查询系统
- **数据源**: `taiwan_cain_web.dnf_item_info` (8.4万条物品)
- **功能**: 物品名称、属性、获取方式、稀有度
- **API**: `/api/v1/item/search?q=xxx`
- **自检**: 随机抽取物品验证属性

### 3. 怪物图鉴
- **数据源**: `taiwan_cain_web.dnf_monster_info` (3148种怪物)
- **功能**: 怪物名称、属性、掉落
- **API**: `/api/v1/monster/search?q=xxx`

### 4. 技能查询
- **数据源**: `taiwan_cain_web.skill_info` (7076个技能)
- **功能**: 技能名称、效果、冷却、消耗
- **API**: `/api/v1/skill/search?q=xxx`

## 二、统计分析类功能

### 5. 服务器状态监控
- **数据源**: `taiwan_cain_log.concurrent_user_status` (2651条)
- **功能**: 实时在线人数、历史趋势
- **API**: `/api/v1/stats/online`
- **自检**: 对比游戏登录界面显示

### 6. 经济系统监控
- **数据源**: `taiwan_cain_2nd.gold` (8.4万条)
- **功能**: 金币流通、交易趋势
- **API**: `/api/v1/stats/economy`

### 7. 副本统计
- **数据源**: `taiwan_cain_log.log_dungeon_entrance_hour` (1.1万条)
- **功能**: 副本进入次数、通关率
- **API**: `/api/v1/stats/dungeon`

### 8. PVP 排行榜
- **数据源**: `d_taiwan.max_count_pvp` (53万条)
- **功能**: PVP 排名、胜率统计
- **API**: `/api/v1/stats/pvp`

## 三、GM 管理类功能

### 9. 封禁管理优化
- **数据源**: `d_taiwan.accounts` + `taiwan_cain.charac_info`
- **功能**: 批量封禁、自动封禁、封禁日志
- **API**: `/api/v1/punish/batch`

### 10. 邮件系统管理
- **数据源**: `taiwan_cain_2nd.postal`
- **功能**: 群发邮件、附件管理、邮件日志
- **API**: `/api/v1/mail/send`

### 11. 活动管理
- **数据源**: `d_taiwan` 活动相关表
- **功能**: 活动配置、奖励发放、活动统计
- **API**: `/api/v1/event/create`

## 四、贴吧 + 游戏联动功能

### 12. 贴吧帖子关联角色
- **数据源**: `dnf_tieba.tieba_posts` + `taiwan_cain.charac_info`
- **功能**: 帖子中提到的角色自动关联
- **API**: `/api/v1/tieba/link/:tid`

### 13. 玩家反馈追踪
- **数据源**: 贴吧帖子 + 游戏日志
- **功能**: 玩家反馈 → 问题定位 → 解决追踪
- **API**: `/api/v1/feedback/track`

### 14. 版本更新监控
- **数据源**: 贴吧帖子 + 游戏数据
- **功能**: 监控版本更新讨论、BUG 反馈
- **API**: `/api/v1/tieba/monitor`

## 五、数据自检方案

### 自动化自检流程
1. **定时采集**: 每小时采集游戏数据
2. **对比验证**: 对比贴吧反馈与实际数据
3. **异常检测**: 检测数据异常（如金币暴涨、等级异常）
4. **报告生成**: 生成自检报告

### 自检脚本
```bash
# 每小时运行
0 * * * * /root/.openclaw/workspace/scripts/dnf-data-collector.sh all
# 每天运行自检
0 0 * * * /root/.openclaw/workspace/scripts/dnf-self-check.sh
```
