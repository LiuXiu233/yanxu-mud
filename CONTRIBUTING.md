# 参与贡献

感谢参与言域。提交应当小步、可审阅、可构建，并保持中文公共 API 一致。

## 开发环境

```bash
git clone https://github.com/LiuXiu233/yanxu-mud.git
cd yanxu-mud
yanxu 包 锁 .
yanxu 查 src/言域.yx
yanxu 试 tests
```

提交前运行仓库的 `scripts/verify.ps1`（Windows）或 `scripts/verify.sh`（Linux/macOS）。不要提交 `.yanxu`、构建目录、数据库、日志、令牌或本地配置。

## 设计要求

- 世界内核不得导入 Telnet、ANSI、HTML、WebSocket 或具体数据库实现。
- 静态内容使用言据，行为只引用由言序注册的稳定编号。
- 所有时间来源可注入，测试使用虚拟时钟。
- 新公共能力必须有中文 API 文档、错误代码和测试。
- 新仓储实现必须通过统一契约测试；新渲染器不得改变消息模型。

## 提交与评审

采用 Conventional Commits 风格的自然中文说明，例如 `feat: 实现事件预算控制`。提交元数据不得包含自动生成工具署名。提交前查看 `git diff --cached` 和 `git status`，确认没有密钥、缓存或临时文件。

行为变更需同步更新 `CHANGELOG.md`。安全问题不要提交公开 Issue，请按 `SECURITY.md` 私下报告。
