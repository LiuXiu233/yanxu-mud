# Web 客户端与 HTTP 管理

## 启动

```bash
cd examples/青石镇
yanxu 包 运行 . -- --模式 HTTP --地址 127.0.0.1:8080 --存档 .yanxu/http-state.json
```

浏览器访问 `http://127.0.0.1:8080/`。页面、样式、脚本和地图均来自 `examples/青石镇/web`；脚本直接连接独立 WebSocket 入口。所有静态响应使用 `no-store`，并携带 `nosniff`、同源 Referrer Policy 和 CSP。静态路径拒绝绝对路径、空段、`.`、`..`、反斜杠和 NUL。

## 端点

| 方法与路径 | 权限 | 说明 |
| --- | --- | --- |
| `GET /`、`GET /assets/*` | 公开 | 浏览器客户端与资源 |
| `GET /healthz` | 公开 | 进程健康状态 |
| `GET /api/v1/server` | 公开 | 引擎、游戏和安全功能投影 |
| `GET /api/v1/online` | 公开 | 当前进程连接与会话摘要 |
| `POST /api/v1/login` | 公开 | 共享同一网关的嵌入宿主登录边界 |
| `GET /api/v1/content` | 公开 | 当前内容版本与摘要 |
| `GET /api/v1/ws` | 公开 | 返回 426 和 `x-yanyu-websocket-url` 发现首部 |
| `POST /api/v1/admin/hot-reload` | Bearer | 内容候选验证与应用结果 |
| `POST /api/v1/admin/snapshot` | Bearer | 创建当前仓储快照 |
| `GET /api/v1/admin/logs` | Bearer | 按 `cursor`、`limit` 查询事实日志 |
| `GET /api/v1/admin/diagnostics` | Bearer | 游戏、仓储、会话与日志诊断 |

JSON 响应使用 `言域/HTTP管理` v1 信封并设置 `cache-control: no-store`。服务异常转换为稳定错误，不返回原始踪迹、密钥或 Authorization。

## 管理认证

青石镇只从 `YANYU_ADMIN_TOKEN` 读取管理令牌，请求使用 `Authorization: Bearer <token>`。缺少环境变量时所有管理操作都拒绝；不存在默认令牌，也不会从查询参数或 Cookie 读取。比较使用固定长度 SHA-256 摘要和标准库恒时比较。

`POST /api/v1/login` 适合在同一进程中共享网关的嵌入宿主。青石镇的独立 HTTP 与 WebSocket 进程不共享内存会话，因此官方浏览器直接在 WebSocket 上发送登录、游客或恢复请求。

## 热重载边界

通用 `包:言域/内容热重载` 提供候选图预检、影响分析、代数检查和原子替换。青石镇网络组合使用确定性运行时分片；摘要未变化时管理端点返回已验证的无操作成功，摘要变化时返回 `QINGSTONE_RELOAD_RESTART_REQUIRED`，不在活动玩法进程中部分替换服务。运维应先构建并校验分片，再安全重启单个玩法进程。

当前 HTTP 服务器来自言枢的串行开发服务器：每连接处理一个 HTTP/1.1 请求并关闭，不提供 TLS、并发池、长连接、分块正文或优雅滚动重启。生产部署需要受支持的嵌入宿主或反向代理，并保持应用监听在回环地址。
