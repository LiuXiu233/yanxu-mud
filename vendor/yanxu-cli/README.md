# 言令

言令（`yanxu-cli`）是纯言序的声明式命令行解析库，支持长短选项、组合短开关、`--name=value`、`--no-name`、类型转换、默认值、重复选项、位置参数、余项、子命令与中文帮助。

## 安装

使用言包添加到当前项目：

```sh
yanbao add 言令 --git https://github.com/yanxulang/yanxu-cli.git --version '^0.1'
```

```yanxu
引「包:言令」为 言令；

定 程序 为 言令.命令（「构建器」，「构建项目」）；
程序.加开关（「verbose」，「v」，「详细输出」）
    .加默认选项（「port」，「p」，「端口」，「数」，「监听端口」，3000）
    .加参数（「入口」，「入口文件」，真）；

定 结果 为 程序.解析当前（）；
```

解析错误统一使用 `YANLING_` 前缀；`尝试解析` 会把错误和帮助文字一起返回，方便应用决定退出码。

```sh
yanxu 查 src/言令.yx
yanxu 试 tests
yanxu 字节 tests/参数解析.yx
```

公共接口见 [docs/API.md](docs/API.md)。本项目采用 MIT 许可证。
