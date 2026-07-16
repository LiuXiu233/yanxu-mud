# 言枢

[![CI](https://github.com/yanxulang/yanxu-web/actions/workflows/ci.yml/badge.svg)](https://github.com/yanxulang/yanxu-web/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Yanxu 1.1.5](https://img.shields.io/badge/言序-1.1.5-b33.svg)](https://github.com/yanxulang/yanxu)

言枢是面向言序的 Web 应用框架。技术包标识与仓库地址继续使用`yanxu-web`，应用源码建议把它引为`言枢`：

```yanxu
引「包:web」为 言枢；
```

0.2 在原有路由、中间件和开发服务器之上加入配置、命名路由、反向 URL、路由组、自定义状态处理器、JSON 正文、无端口测试客户端，以及内建模板子项目“言标”。

```text
言枢（yanxu-web）
├── 应用配置 · 路由组 · 命名路由 · 反向 URL
├── 请求上下文 · 中间件 · 404/405/500 · 测试客户端
├── 言标：自动转义 · 条件 · 循环 · 包含 · 模板继承
├── 静态文件 · 开发服务器
├── yanxu-html：底层 HTML 节点与安全规则
└── yanxu-http：HTTP/1.1 请求与响应
```

## 快速开始

```sh
yanbao add web --version '^0.2'
```

`web`会自动解析为 GitHub 上的`yanxulang/yanxu-web`，并由言包锁定其 HTML 与 HTTP 传递依赖。

```yanxu
引「包:web」为 言枢；

定 配置项 为 言枢.配置（）
    .设应用名（「我的站点」）
    .设模板根（「templates」）
    .设静态根（「static」）；

定 应用 为 言枢.创建应用（配置项）；

法 首页（上下文）则
    归 应用.模板响应（「home.yb.html」，{
        「标题」：「你好，言枢」，
        「文章地址」：上下文.反向（「文章详情」，{「id」：「first」}）
    }）；
终

法 文章（上下文）则
    归 言枢.JSON响应（{「id」：上下文.参数值（「id」）}）；
终

应用.命名取（「/」，「首页」，首页）；
应用.命名取（「/posts/:id」，「文章详情」，文章）；
应用.挂配置静态（「/static」）；

言枢.服务器（应用，「127.0.0.1:8080」）.运行（）；
```

`templates/home.yb.html`使用言标语法：

```html
<!doctype html>
<h1>{{ 标题 }}</h1>
<a href="{{ 文章地址 }}">阅读文章</a>
```

插值默认 HTML 转义。条件、循环、包含和继承都使用中文控制词：

```html
{% 承 base.yb.html %}
{% 块 主体 %}
  {% 若 已登录 %}<p>欢迎，{{ 用户.姓名 }}</p>{% 否则 %}<p>请登录</p>{% 终若 %}
  {% 逐 文章 于 文章列 %}<a href="{{ 文章.url }}">{{ 文章.title }}</a>{% 终逐 %}
{% 终块 %}
```

## 框架能力

- `言枢配置`集中管理应用名、模板根、静态根、调试标记和默认 CSP；
- 静态、`:参数`和末尾`*通配`路由，自动区分 404 与 405；
- 命名路由、命名空间路由组与百分号编码的反向 URL；
- GET、POST、PUT、PATCH、DELETE 便捷注册；
- 洋葱式中间件、可替换 404/405 和统一 500 错误边界；
- 上下文读取路径、查询、首部、Cookie、正文、JSON、AJAX 标记和应用状态；
- HTML 节点、言标模板、JSON、言据、文字、字节、重定向和空响应；
- 静态目录穿越防护与默认安全响应首部；
- `言枢测试客户端`直接驱动完整应用链，不占用 TCP 端口。

## 言标安全模型

`{{ 值 }}`总是 HTML 转义；模板文件中的静态 HTML 原样保留。动态内容只有经`言枢.言标.信任HTML（内容）`显式包装后才能绕过转义。可信包装是审计边界，不是清洗器，不能接收用户、数据库、接口或文件中的未审计内容。

模板文件必须使用`.yb.html`扩展名。加载器拒绝绝对路径、反斜杠、NUL、`.`、`..`、循环包含和超过 16 层的包含链，单模板源码上限为 256 KiB。

完整语法见[言标参考](docs/yanbiao.md)。

## 安装与测试

```sh
git clone https://github.com/yanxulang/yanxu-web.git
yanbao install --manifest-path yanxu-web
yanxu 查 yanxu-web/src/言序Web.yx
yanxu 试 yanxu-web/tests --并发 1 --json
```

言包按`言序.toml`安装`yanxu-html`和`yanxu-http`，`言序.lock`固定精确提交与内容校验。并发规格会让多个进程同时检出同一 Git 缓存，因此仓库门禁使用`--并发 1`。

## 兼容与边界

0.1 的`Web.应用()`、`Web应用`、`Web上下文`、`Web开发服务器`和响应工厂继续可用；新代码建议使用“言枢”模块别名、`创建应用`、`言枢应用`、`言枢上下文`和`服务器`。迁移清单见[0.2 迁移说明](docs/migration-0.2.md)。

开发服务器仍是串行 HTTP/1.1、一连接一请求、`Connection: close`模型，适合本地开发、教学和集成验证，不承诺 TLS、并发工作池、长连接、流式上传、生产日志或优雅重启。

## 文档

- [入门教程](docs/getting-started.md)
- [公开 API](docs/api.md)
- [言标语法](docs/yanbiao.md)
- [架构与请求生命周期](docs/architecture.md)
- [0.2 迁移说明](docs/migration-0.2.md)
- [完整言枢博客](https://github.com/yanxulang/yanxu-webblog)

当前版本为`0.2.1`，并以清单格式 2 显式导出默认框架模块与`言标`子模块。按[MIT License](LICENSE)发布。
