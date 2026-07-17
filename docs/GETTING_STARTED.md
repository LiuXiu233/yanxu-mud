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

## 调用公共入口

```yanxu
引「包:言域」为 言域；

定 信息：典 为 言域.服务器信息（）；
言 信息【「版本」】；
```

## 检查示例内容

青石镇内容包可以直接检查、装载或构建为带摘要的言据制品：

```bash
yanxu tools/言域.yx -- 内容检查 --行为 言域:技能行为/伤害 examples/青石镇/内容
yanxu --max-steps 20000000 tools/言域.yx -- 构建 --行为 言域:技能行为/伤害 --输出 青石镇世界.yj examples/青石镇/内容
```

```yanxu
引「包:言域/内容加载」为 内容加载；

定 图 为 内容加载.构建内容图（【「examples/青石镇/内容」】，「0.4.1」，「zh-CN」，【】，【「言域:技能行为/伤害」】）；
言 图.统计（）；
```

内容包清单、Schema 和热重载边界分别见 [CONTENT_PACKS.md](CONTENT_PACKS.md)、[CONTENT_SCHEMA.md](CONTENT_SCHEMA.md) 和 [HOT_RELOAD.md](HOT_RELOAD.md)。

项目运行权限由 `言序.toml` 显式声明。开发中不要扩大权限以绕过错误；新增文件、网络、进程或原生扩展能力时必须同步更新安全模型和测试。

## 常见问题

- 锁定依赖失败：确认 GitHub 连接后重试；不要手工伪造锁文件。
- 静态检查成功但运行失败：使用 `yanxu 包 运行 . -- 参数`，让清单权限生效。
- 平台能力缺失：查看结构化错误代码，并记录条件跳过原因。
- 内容错误：内容检查会返回文件、言据路径、Schema 路径和稳定错误代码，优先修复第一处根因。
