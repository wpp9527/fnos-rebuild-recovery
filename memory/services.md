# 服务清单

## DNF Admin Pro (192.168.1.204)

| 服务 | 容器名 | 端口 | 状态 |
|------|--------|------|------|
| 后端 API | dnf-public-admin-backend | 18882→8080 | ✅ 运行中 |
| 前端 | dnf-public-admin-frontend | 18883→80 | ✅ 运行中 |
| DNF 游戏服务器 | dnf-llnut_dnf-1_1 | 5505,7001,7300,30011 | ✅ 运行中 |

### 数据源

- **MySQL**: 运行在 `dnf-llnut_dnf-1_1` 容器内，端口 3306
  - 用户: `dnf_readonly` / `dnf_readonly_2024`
  - 账号库: `d_taiwan`
- **PVF 物品数据**: `/opt/dnf-llnut/data/conf.d/dnf-console/source/gold.txt`
  - 格式: `[ID ] name:Name`
  - 数量: 83977 个物品
  - 已实现分类: 武器/防具/首饰/称号/宠物/材料/任务/消耗品/装扮/其他

### API 端点

- `POST /api/v1/auth/login` - 登录
- `GET /api/v1/accounts` - 账号列表
- `GET /api/v1/characters` - 角色列表
- `GET /api/v1/pvf/items?page=1&page_size=20&category=weapon&q=xxx` - PVF 物品（分页+分类+搜索）
- `GET /api/v1/pvf/categories` - PVF 分类列表
- `GET /api/v1/pvf/stats` - PVF 统计

### 前端功能

- ✅ 分页控件（上一页/下一页/页码跳转）
- ✅ 分类筛选（全部/武器/防具/首饰/称号/宠物/材料/任务/消耗品/装扮/其他）
- ✅ 搜索功能
- ✅ 物品详情预览
- ✅ GM 操作联动（发放/邮件）

---

## FNOS 媒体栈 (192.168.1.212)

全部 19 个容器运行中，详见 memory/2026-06-05.md。
