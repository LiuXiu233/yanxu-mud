# yanxu-html

[![CI](https://github.com/yanxulang/yanxu-html/actions/workflows/ci.yml/badge.svg)](https://github.com/yanxulang/yanxu-html/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Yanxu 1.1.5](https://img.shields.io/badge/言序-1.1.5-b33.svg)](https://github.com/yanxulang/yanxu)

`yanxu-html` 是言序的默认安全 HTML 节点、元素、属性、文档与组件基础库。它把“普通内容”和“已经受信任的原始 HTML”分成不同类型，让自动转义成为默认路径，让绕过转义成为需要显式表达的决定。

```text
应用数据 ──> 文字 / 属性 ──> 自动转义 ──> HTML
可信源码 ──> 原始          ──> 原样输出 ──> HTML
```

## 主要能力

- `HTML文字节点`和文字属性值在渲染时自动转义；
- `HTML原始内容`只能直接构造或通过名称明确的`原始`工厂创建；
- 标签名、属性名采用保守 ASCII 白名单；
- URL 属性默认拒绝危险协议、空白和控制字符；
- HTML5 空元素不能添加子节点；
- `HTML组件`延迟构建节点，`HTML文档`固定输出 HTML5 doctype；
- 不依赖其他第三方言序包，适合作为 Web 栈最底层。

## 快速开始

使用官方包管理器[言包](https://github.com/yanxulang/yanbao)添加依赖：

```sh
yanbao add html --version '^0.1'
```

`html`会自动解析为 GitHub 上的`yanxulang/yanxu-html`。言包把精确提交与内容校验写入`言序.lock`；项目不需要复制源码或维护 submodule。

然后创建页面：

```yanxu
引「包:html」为 HTML；

定 页面 为 HTML.文档（
    HTML.元素（「html」，【HTML.属性（「lang」，「zh-CN」）】，【
        HTML.元素（「body」，【】，【
            HTML.元素（「h1」，【】，【HTML.文字（「言序 Web」）】），
            HTML.元素（「a」，【HTML.属性（「href」，「/docs」）】，【
                HTML.文字（「阅读文档」）
            】）
        】）
    】）
）；

言 HTML.安全渲染（页面）；
```

输出：

```html
<!doctype html>
<html lang="zh-CN"><body><h1>言序 Web</h1><a href="/docs">阅读文档</a></body></html>
```

## 默认安全边界

普通文字和属性值会转义`&`、`<`、`>`、引号等 HTML 特殊字符。`href`、`src`、`action`、`formaction`、`poster`和`xlink:href`只接受无显式协议的地址以及`http:`、`https:`、`mailto:`、`tel:`；`javascript:`、`data:`、未知协议及含空白或控制字符的地址会在构造属性时失败。

```yanxu
HTML.文字（「<script>坏内容</script>」）；       # 安全：输出被转义的文字
HTML.属性（「href」，「javascript:坏内容」）；   # 失败：危险协议
HTML.原始（「<strong>可信源码</strong>」）；     # 显式绕过转义
```

`原始`不做清洗，只能接收开发者已经审计的常量或可信生成结果。库也不解析 CSS、脚本内容或复杂 SVG；这些上下文需要应用自行建立更严格的策略。完整规则见[安全模型](docs/security.md)。

## 文档

- [入门与组合方式](docs/getting-started.md)
- [公开 API 参考](docs/api.md)
- [安全模型与信任边界](docs/security.md)
- [言序文档站：安全 HTML](https://docs.yanxu.dev/web/html/)

可运行示例在[`examples/组件.yx`](examples/组件.yx)，安全回归测试在[`tests/安全渲染.yx`](tests/安全渲染.yx)。

## 开发与验收

始终从言序总工作区根目录运行：

```sh
yanxu-language-new/target/debug/yanxu 查 yanxu-html/src/言序HTML.yx
yanxu-language-new/target/debug/yanxu 试 yanxu-html/tests --json
yanxu-language-new/target/debug/yanxu 执 yanxu-html/examples/组件.yx
```

## 状态与范围

当前版本是 `0.1.1`。这一版本专注服务端 HTML 字符串构建，不包含 HTML 解析、DOM、模板文件编译、CSS 清洗或浏览器运行时。版本规划与跨库依赖关系见[言序 Web 开发总览](https://docs.yanxu.dev/web/)。

按 [MIT License](LICENSE) 发布。
