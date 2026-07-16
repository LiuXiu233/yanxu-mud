# 言序生态调研

调研时间：2026-07-16（UTC+8）。本记录直接检查了各仓库的默认分支、提交、`README.md`、`言序.toml`、锁文件、公开 API 文档、实现源码、测试和 CI；没有依据仓库名猜测接口。

## 工具链基线

言域 1.0 以已发布的 [言序 1.1.7](https://github.com/yanxulang/yanxu/releases/tag/v1.1.7) 为编译与运行基线。本机发行构建提交为 `7d0e8b2b7bdd1125a7d271bce690ab854c79c31c`。调研时 `yanxulang/yanxu` 的 `main` 已是未发布的 1.1.8，因此不能把它写成稳定依赖。工程操作使用已发布的 [言包 0.5.0](https://github.com/yanxulang/yanbao/releases/tag/v0.5.0)，不把言包作为世界运行时库。

言序 1.1.7 可用的相关标准库包括 TCP/UDP 套接字、字节、文件、JSON、进程、哈希/HMAC/恒时比较、安全随机、标识、时间、路径和测试断言。标准库没有 HTTP 服务端、WebSocket、Telnet、TLS、密码哈希或 SQLite 模块。

## 采用依赖

除言据和言枢外，下表中的 0.x 库均没有 GitHub Release；清单和锁文件固定精确提交，并通过言域自己的协议适配层隔离其 API。

| 能力 | 仓库 / 包 | 调研版本与固定提交 | 采用范围 | 边界 |
| --- | --- | --- | --- | --- |
| 言据 | [`yanju`](https://github.com/yanxulang/yanju) / `言据` | 1.1.2 / [`765d9dd6`](https://github.com/yanxulang/yanju/commit/765d9dd623db901a3e71aa4759dbcd77563cb3a9) | `.yj` 解析、确定性序列化、基础 Schema、路径、合并、差异、流 | 文件写入不是原子替换；跨包引用、迁移、影响分析和热重载事务由言域实现 |
| 输入校验 | [`yanxu-validate`](https://github.com/yanxulang/yanxu-validate) / `言验` | 0.1.0 / [`5d19fb86`](https://github.com/yanxulang/yanxu-validate/commit/5d19fb86159d8eaa12a252a92a230a8052260cbe) | CLI、HTTP、管理输入的链式验证与结构化问题 | 规则可包含闭包，不能作为内容 Schema 交换；内容第一层仍用言据规则 |
| 结构化日志 | [`yanxu-log`](https://github.com/yanxulang/yanxu-log) / `言录` | 0.1.0 / [`ac2266e1`](https://github.com/yanxulang/yanxu-log/commit/ac2266e1ec4f70067176e39964f096471eb3196b) | 分级、上下文、处理器与诊断日志 | 由安全适配器扩充大小写敏感键、清洗错误消息；不能单独承担强审计事件存储 |
| 时间 | [`yanxu-datetime`](https://github.com/yanxulang/yanxu-datetime) / `言时` | 0.1.0 / [`c36fefc7`](https://github.com/yanxulang/yanxu-datetime/commit/c36fefc789979a54c1aa1da4e6c35a90cbb3edd4) | 时间值对象、时钟协议、系统/虚拟时钟 | 重复定时器是轮询对象，不是持久调度器；世界调度由言域事件队列实现 |
| 测试 | [`yanxu-test`](https://github.com/yanxulang/yanxu-test) / `言试` | 0.1.0 / [`8f3bc2cb`](https://github.com/yanxulang/yanxu-test/commit/8f3bc2cb9c7b98175dde0ee6323bae91edbb8535) | 深断言、Mock/Spy、虚拟钟、快照和数据库测试辅助 | 仍需言域自己的仓储契约、套接字、重放、热重载和安全测试 |
| CLI | [`yanxu-cli`](https://github.com/yanxulang/yanxu-cli) / `言令` | 0.1.0 / [`8f68e6a4`](https://github.com/yanxulang/yanxu-cli/commit/8f68e6a46fcdcfea57768641d99686d6f56545b3) | `tools/言域.yx` 的 OS 参数、子命令和帮助 | 不用于玩家命令；玩家命令另有引号、权限、冷却和中间件协议 |
| 数据库协议 | [`yanxu-db`](https://github.com/yanxulang/yanxu-db) / `言库` | 0.1.0 / [`354a9b1d`](https://github.com/yanxulang/yanxu-db/commit/354a9b1d756276de06cd707606e4630323401e0b) | 连接、事务、结果、方言、参数和连接池边界 | 世界内核只依赖言域状态仓储；言库仅在 SQLite 适配器内部出现 |
| SQLite | [`yanxu-sqlite`](https://github.com/yanxulang/yanxu-sqlite) / `言舟` | 0.1.0 / [`425650a0`](https://github.com/yanxulang/yanxu-sqlite/commit/425650a0a6fa72fe9f239d39b749d38a173495d4) | SQLite 3.38+ CLI 后端、参数化 SQL、事务批、保存点和迁移 | 默认后端要求 `sqlite3` 在 PATH 且顶层授予进程权限；无 CLI 时明确条件跳过，不回退成伪 SQLite |
| Web | [`yanxu-web`](https://github.com/yanxulang/yanxu-web) / `yanxu-web`（别名 `言枢`） | 清单 0.2.1 / [`0bc3b2f1`](https://github.com/yanxulang/yanxu-web/commit/0bc3b2f162667fa29600aab0cd1d83306fb89eff)；最新 Release 0.2.0 | 管理 HTTP、路由、中间件、静态客户端、无端口集成测试 | 开发服务器串行、一连接一请求，不承诺生产并发、TLS、长连接或优雅重启 |
| HTTP | [`yanxu-http`](https://github.com/yanxulang/yanxu-http) / `yanxu-http` | 0.1.1 / [`c2356ae7`](https://github.com/yanxulang/yanxu-http/commit/c2356ae7be9948b770c68a07a68fd87df207570a) | 传递依赖；有界 HTTP/1.1 请求解析与响应编码 | 仅 `Content-Length`、`Connection: close`，不支持 WebSocket 升级或公网生产服务 |
| HTML | [`yanxu-html`](https://github.com/yanxulang/yanxu-html) / `yanxu-html` | 0.1.1 / [`a057a014`](https://github.com/yanxulang/yanxu-html/commit/a057a014a9a85fe67181b11aedcc6e7bfe64cfcd) | 传递依赖；自动转义节点和安全属性 | `原始`是显式信任边界，不是清洗器；不用于世界消息模型 |

## 已评估但未作为 1.0 运行时依赖

| 仓库 | 实际状态 | 决策 |
| --- | --- | --- |
| [`yanxu-orm`](https://github.com/yanxulang/yanxu-orm) / `言映` | 0.1.0，提交 [`ee95de44`](https://github.com/yanxulang/yanxu-orm/commit/ee95de44c9c9eedaccfe8a50daacef118cfafa95)，提供模型、查询、关系、脏字段、加法迁移和事务单元 | 言域状态是实体组件快照与变更集，不以行模型为公共边界。1.0 直接用言库/言舟适配，避免 ORM 类型侵入领域；应用插件仍可自行使用言映。 |
| [`yanxu-platform`](https://github.com/yanxulang/yanxu-platform) / `yanxu-platform` | 0.1.0 Release，提交 [`5eae4238`](https://github.com/yanxulang/yanxu-platform/commit/5eae423889725bb04eb5cdc79e0594524ac7293a)，ABI v2 平台窗口/事件/绘制原语 | MUD 1.0 的官方客户端是浏览器和终端，不申请 GUI/原生扩展权限。后续桌面编辑器可独立采用。 |
| [`yanxu-gui`](https://github.com/yanxulang/yanxu-gui) / `言窗` | 0.1.0 Release，提交 [`9e8065a5`](https://github.com/yanxulang/yanxu-gui/commit/9e8065a5c46d5fcf25e5134d7297f175ef03ec43)，ABI v2 高级控件包 | 与言台相同，避免把桌面后端和六平台原生制品带入服务器；内容编辑器作为 1.x 可选工具。 |

## 关键风险与补偿设计

### 接入容量

言序 1.1.7 标准套接字为阻塞 I/O，开放套接字硬上限 128、监听器上限 16，不能满足 1000 个真实网络会话。纯言序适配器用于协议正确性、本地开发和小型服务器；生产 1000 会话通过独立接入进程或经审计的 ABI v2 原生扩展承载，仍只向纯言序世界内核发送结构化请求。基准中的 100/1000 会话是无套接字模拟会话，不能误报为并发网络容量。

### 密码与传输安全

标准库只有 SHA-256、HMAC-SHA-256、恒时比较和安全随机，没有 Argon2、scrypt、bcrypt 或 PBKDF2。言域不自行实现密码学算法；密码哈希协议必须接入可靠原生库。Telnet 无传输加密，公网部署必须使用 TLS 终止代理；HTTP/WebSocket 同样由反向代理提供 TLS、来源策略和请求限制。

### 文件持久性

言据的 `写入/美写` 直接覆盖文件，标准文件 API 没有原子重命名、fsync 或锁。言据文件仓储使用内容寻址世代、SHA-256 校验和、提交指针和启动恢复检查；SQLite 事务作为生产默认。日志文件也不是强审计存储，重要领域事实进入独立事件日志仓储。

### Schema 与热重载

言据规则适合可交换的结构检查，但没有 `$ref`、条件、默认迁移、跨包引用或行为引用。言域在其上增加组件/内容 Schema 注册表、依赖图、引用解析、迁移计划、差异影响分析和原子应用；验证失败时继续使用旧内容图。

### 权限

依赖不能替顶层应用提权。服务器和示例游戏必须显式授予内容/日志/快照文件路径、回环 TCP 监听，以及使用言舟 CLI 时的进程权限。世界核心模块本身不调用文件、网络、进程或原生扩展。

## 更新纪律

升级任何固定提交前，必须重新读取清单、公开 API、实现和测试，运行 Windows/Linux/macOS 矩阵，并记录 API/行为差异。不得只因上游 `main` 更新而自动漂移 1.0 锁文件。
