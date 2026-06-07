# dnf-public-admin 接线说明

## 原则

- 旧后台 `dnf-console` 保留，端口 `882` 继续作为生产管理入口，直到新后台完成只读核验和写操作审计闭环。
- 新后台保留独立管理库，只保存管理员、RBAC、审计、收藏等后台自身数据。
- 游戏业务数据继续由 `104 / dnf-llnut` 的现有 MySQL 提供。
- 公开仓不保存真实密码、密钥、域名与 IP。

## 端口一致性

| 入口 | 默认端口 | 说明 |
| --- | ---: | --- |
| `dnf-console` 旧后台 | `882` | 生产事实入口 |
| supervisor | `2000` | 原 llnut 管理入口 |
| game login | `3000` | 登录器/游戏入口 |

如果需要预览新后台，应使用独立预览端口，不要覆盖 `882`。

## 数据库接线

| 数据域 | 数据库 |
| --- | --- |
| 账号 | `d_taiwan` |
| 登录 | `taiwan_login` |
| Cain | `taiwan_cain` |
| Cain 二级数据 | `taiwan_cain_2nd` |
| 计费/点券 | `taiwan_billing` |

## 建议接线步骤

1. 私有部署仓提供数据库连接参数与网络出口。
2. `dnf-public-admin` 第一阶段使用只读数据库账号接入游戏库。
3. 先完成账号/角色/活动/PVF 的只读核验。
4. PVF 文件由私有部署仓统一挂载到后台导入目录。
5. 发放、充值、封禁、活动开关等写操作必须先接入 RBAC 与审计日志。
6. 写操作启用前，与旧后台同一条数据链路做对比验证，禁止双写到新库。


## Schema inspection

在新后台切换到 live 只读模式前，使用只读账号执行：

```bash
ENV_FILE=env/.env.local scripts/schema-inspect.sh
```

输出的表结构应再提交给 `dnf-public-admin` 的：

```text
POST /api/v1/meta/llnut-schema/validate
```

校验通过后，才能把账号/角色/计费读取从 demo 数据切到 live 只读数据。


本地已有 schema JSON 后，可直接执行：

```bash
DNF_PUBLIC_ADMIN_API_URL=http://127.0.0.1:18882 scripts/validate-schema.sh docs/schema-validation-example.json
```


如果 `schema-inspect.sh` 输出为行格式，可转换为校验接口需要的 JSON：

```bash
ENV_FILE=env/.env.local scripts/schema-inspect.sh | scripts/schema-to-json.py > /tmp/llnut-schema.json
scripts/validate-schema.sh /tmp/llnut-schema.json
```


## Live-readonly mode

schema 校验和旧后台对比通过后，才允许将新后台设置为：

```env
LLNUT_MODE=live-readonly
```

当前仍无写模式；GM、活动、PVF 发放仍需通过后续灰度门禁。
