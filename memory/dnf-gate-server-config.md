# dnf-gate-server 配置说明

## 网关配置
| 变量 | 默认值 | 说明 |
|------|--------|------|
| GATE_AES_KEY | - | AES 通讯密钥，需与登录器配置一致 |
| GATE_BIND_ADDRESS | 0.0.0.0:5505 | HTTP 监听地址 |
| RSA_PRIVATE_KEY_PATH | /data/privatekey.pem | RSA 私钥路径 |
| INITIAL_CERA | 1000 | 新账号初始点券 |
| INITIAL_CERA_POINT | 0 | 新账号初始代币券 |
| GATE_RUST_LOG | info,dnf_gate_server=debug | 日志级别 |
| GATE_TLS_CERT_PATH | 无 | TLS 证书路径 |
| GATE_TLS_KEY_PATH | 无 | TLS 私钥路径 |
| GATE_TLS_BIND_ADDRESS | 0.0.0.0:5504 | HTTPS 监听地址 |
| GATE_TLS_ONLY | false | 仅允许 HTTPS 连接 |
| GAME_SERVER_IP | PUBLIC_IP | 游戏服务器 IP |

## AES 密钥格式
- 长度: 32 字节 (256-bit)
- 示例: `a1b2c3d4e5f6789012345678901234567890abcdef0123456789abcdef012345`

## 关键点
1. GATE_AES_KEY 必须与登录器配置一致
2. RSA 用于登录验证
3. GAME_SERVER_IP 用于转发到游戏服务器
4. 新账号自动获得 INITIAL_CERA 点券
