# yanxu-html 入门

`yanxu-html`用类型区分普通文字、属性、元素、组件、完整文档和原始内容。最重要的使用原则只有一条：来自用户、数据库、文件或网络的内容始终进入`文字`或`属性`，不要进入`原始`。

## 1. 添加依赖

使用言包添加官方 GitHub 包并生成锁文件：

```sh
yanbao add html --version '^0.1'
yanbao install
yanbao run
```

清单保留可读的 Git 来源与版本要求，`言序.lock`固定实际提交和 SHA-256 内容校验。日常恢复使用`install`；需要重新选择`main`的新提交时显式执行`yanbao update`。

## 2. 从文字节点开始

```yanxu
引「包:html」为 HTML；

定 标题：文 为「<言序与 Web>」；
定 节点 为 HTML.元素（「h1」，【】，【HTML.文字（标题）】）；
言 节点.渲染（）；
```

结果是`<h1>&lt;言序与 Web&gt;</h1>`。文字在最后渲染时转义，不要求调用者提前处理，也不要先手工转义后再传入，否则会产生重复转义。

## 3. 添加属性和子节点

```yanxu
定 卡片 为 HTML.元素（「article」，【
    HTML.属性（「class」，「post-card」），
    HTML.属性（「hidden」，假）
】，
【HTML.文字（「第一篇文章」）】）；

卡片.添属性（HTML.属性（「data-id」，「hello」））；
卡片.添子（HTML.元素（「a」，【HTML.属性（「href」，「/posts/hello」）】，【
    HTML.文字（「继续阅读」）
】））；
```

属性值为`真`时输出布尔属性，为`假`或`空`时省略。所有属性必须是`HTML属性`，所有子项必须是`HTML节点`；传入未包装的文字会立即失败。

## 4. 提取组件

组件持有一个无参构建法，并要求其返回 HTML 节点：

```yanxu
法 构建欢迎卡（）则
    归 HTML.元素（「section」，【HTML.属性（「class」，「welcome」）】，【
        HTML.元素（「h2」，【】，【HTML.文字（「欢迎」）】）
    】）；
终

定 页面组件 为 HTML.组件（构建欢迎卡）；
言 页面组件.渲染（）；
```

构建法可以闭包捕获页面数据。若需要参数化组件，也可以先写普通法，让它直接返回一个节点。

## 5. 输出完整文档

```yanxu
定 页面 为 HTML.文档（HTML.元素（「html」，【HTML.属性（「lang」，「zh-CN」）】，【
    HTML.元素（「head」，【】，【
        HTML.元素（「meta」，【HTML.属性（「charset」，「utf-8」）】，【】），
        HTML.元素（「title」，【】，【HTML.文字（「我的站点」）】）
    】），
    HTML.元素（「body」，【】，【页面组件】）
】））；

言 HTML.安全渲染（页面）；
```

`文档`固定添加`<!doctype html>`。如果要把节点直接作为 HTTP 响应返回，使用`yanxu-web`的`Web.HTML响应（节点）`，它会调用同一安全渲染路径。

## 下一步

- 查询所有公开类型和工厂：[API 参考](api.md)
- 理解危险协议、原始内容和非目标：[安全模型](security.md)
- 查看完整应用：[yanxu-webblog](https://github.com/yanxulang/yanxu-webblog)
