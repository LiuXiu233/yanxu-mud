# 入门

## 准备工具链

安装言序 1.1.12 和 SQLite 3.38.0 以上版本，并确认：

```bash
yanxu 版本 --json
sqlite3 --version
yanxu 包 .
```

如果 `sqlite3` 不在 `PATH`，将 `YANYU_SQLITE3` 设置为 CLI 的绝对路径。完整测试包含真实 SQLite 数据库往返，不会在缺少 CLI 时静默跳过。

首次克隆后锁定依赖并验证：

```bash
yanxu 包 锁 .
yanxu 查 src/言域.yx
yanxu 查 tools/言域.yx
yanxu 试 tests --json
yanxu 编 . -o build --release
```

## 运行青石镇

从仓库根目录通过统一 CLI 启动独立游戏包：

```bash
yanxu 包 运行 . -- 运行 --命令 观察 --命令 背包 --存档 .yanxu/青石镇存档.json examples/青石镇
```

`运行`、`run`、`控制台` 和 `console` 使用同一游戏包启动边界。默认是本地控制台：命令可重复，按给定顺序执行；加 `--json` 可取得结构化报告。也可以进入 `examples/青石镇` 后直接执行 `yanxu 包 运行 . -- --命令 观察`。玩法、网络端到端和兼容测试保持默认 1,000,000 步预算，只有下述完整内容构建显式提高预算。

## 启动网络服务

青石镇把 HTTP、WebSocket 与 Telnet 作为三个独立进程运行。先在一个终端启动 WebSocket 游戏入口：

```bash
cd examples/青石镇
yanxu 包 运行 . -- --模式 WebSocket --存档 .yanxu/websocket-state.json
```

再在第二个终端启动网页和管理接口：

```bash
cd examples/青石镇
yanxu 包 运行 . -- --模式 HTTP --存档 .yanxu/http-state.json
```

访问 `http://127.0.0.1:8080/`，选择游客即可进入。Telnet 可单独启动并连接：

```bash
cd examples/青石镇
yanxu 包 运行 . -- --模式 Telnet --存档 .yanxu/telnet-state.json
telnet 127.0.0.1 4000
```

服务器模式以 `--地址 主机:端口` 改写监听地址，以 `--次数 N` 在处理 N 个连接或请求后退出。后者用于 `scripts/network-e2e.ps1`，常驻服务保持默认值零。根 CLI 也会转发这些选项，例如 `yanxu 包 运行 . -- 运行 --模式 HTTP examples/青石镇`；长时间运行时直接进入游戏包可以立即看到启动日志。

可选环境变量：

| 变量 | 用途 |
| --- | --- |
| `YANYU_SESSION_SECRET` | 至少 32 字节的会话 HMAC 密钥；缺失时使用进程内临时密钥 |
| `YANYU_LOGIN_NAME` | 示例登录名，须与登录密钥同时配置 |
| `YANYU_LOGIN_SECRET` | 示例登录密钥，仅从环境读取并恒时比较 |
| `YANYU_ADMIN_TOKEN` | HTTP 管理 Bearer 令牌；缺失时所有管理操作拒绝 |

浏览器直接连接 WebSocket 进程，因此 HTTP 和 WebSocket 不共享内存会话。不要让两个可写玩法进程同时使用同一轻量存档路径。

## 调用公共入口

```yanxu
引「包:言域」为 言域；

定 信息：典 为 言域.服务器信息（）；
言 信息【「版本」】；
```

## 检查示例内容

青石镇内容包可以直接检查、装载或构建为带摘要的言据制品：

```bash
yanxu tools/言域.yx -- 内容检查 --行为 言域:技能行为/伤害 --行为 言域:计划行为/刷新 --行为 言域:AI行为/敌对近战 examples/青石镇/内容
yanxu --max-steps 20000000 tools/言域.yx -- 构建 --行为 言域:技能行为/伤害 --行为 言域:计划行为/刷新 --行为 言域:AI行为/敌对近战 --输出 青石镇世界.yj examples/青石镇/内容
```

```yanxu
引「包:言域/内容加载」为 内容加载；

定 图 为 内容加载.构建内容图（【「examples/青石镇/内容」】，「0.7.0」，「zh-CN」，【】，【「言域:技能行为/伤害」，「言域:计划行为/刷新」，「言域:AI行为/敌对近战」】）；
言 图.统计（）；
```

内容包清单、Schema 和热重载边界分别见 [CONTENT_PACKS.md](CONTENT_PACKS.md)、[CONTENT_SCHEMA.md](CONTENT_SCHEMA.md) 和 [HOT_RELOAD.md](HOT_RELOAD.md)。

项目运行权限由 `言序.toml` 显式声明。开发中不要扩大权限以绕过错误；新增文件、网络、进程或原生扩展能力时必须同步更新安全模型和测试。

## 常见问题

- 锁定依赖失败：确认 GitHub 连接后重试；不要手工伪造锁文件。
- 静态检查成功但运行失败：使用 `yanxu 包 运行 . -- 参数`，让清单权限生效。
- 平台能力缺失：查看结构化错误代码，并记录条件跳过原因。
- 内容错误：内容检查会返回文件、言据路径、Schema 路径和稳定错误代码，优先修复第一处根因。
