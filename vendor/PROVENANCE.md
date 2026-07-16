# 固定依赖溯源

本目录包含言域 1.0 构建所需的言序生态源码。源码来自 GitHub 提交归档；为支持完全离线的言包锁定，只修改了四个上游 `言序.toml`，把传递 Git 依赖改为同目录的精确版本路径依赖。其余上游源码、许可和文档保持归档内容。

| 目录 | 上游提交 | 下载归档 SHA-256 |
| --- | --- | --- |
| `yanju` | `765d9dd623db901a3e71aa4759dbcd77563cb3a9` | `03c47ac33473a80dec886f436a58731adef372ae063b82881406fab73c07b47a` |
| `yanxu-validate` | `5d19fb86159d8eaa12a252a92a230a8052260cbe` | `597da1ccf5e0646dda0a426864c066ae82a63c9670c67012c1b03953cac9e3ba` |
| `yanxu-log` | `ac2266e1ec4f70067176e39964f096471eb3196b` | `a102b62e7cd720b18eb87a088ad94d1dc7e8bb4c1b5def0ca666fb6f19b0a797` |
| `yanxu-datetime` | `c36fefc789979a54c1aa1da4e6c35a90cbb3edd4` | `858aff9a9e5d2a58f731ab329d74f7568e8cb705b5de0f6e0b2b066fbad1d76e` |
| `yanxu-test` | `8f3bc2cb9c7b98175dde0ee6323bae91edbb8535` | `e392bdcd8cfc7fcdd252394939acae897b25b063ca695ce80e484c0cd4ee4aec` |
| `yanxu-cli` | `8f68e6a46fcdcfea57768641d99686d6f56545b3` | `c30e077c99ab793add58c01fa055858990aee656440f6a335d5936c070b4dce5` |
| `yanxu-db` | `354a9b1d756276de06cd707606e4630323401e0b` | `f54613ddee90c4f9fecc5a75b757d5c9dcbad9c08d2923fe0fdfc85083b5d0b4` |
| `yanxu-sqlite` | `425650a0a6fa72fe9f239d39b749d38a173495d4` | `685748a082aba9ce55acd46275f9df676016e3669ae4a79ff280ee6a13368d94` |
| `yanxu-web` | `0bc3b2f162667fa29600aab0cd1d83306fb89eff` | `39c955e0121a0b911b4e3a3bc285df837be774e4552b5e44415964312fc69cc4` |
| `yanxu-http` | `c2356ae7be9948b770c68a07a68fd87df207570a` | `2369bde43b80c5fc8855a967720181eb10ae0a84c2b0bf988d2eac176a462db5` |
| `yanxu-html` | `a057a014a9a85fe67181b11aedcc6e7bfe64cfcd` | `279d75e07f4c3d659185207cb61dec05f11701b894be39a8278675a1b28ccb5e` |

升级步骤：重新读取上游清单/API/源码/测试，下载指定提交归档，核对归档摘要，重新应用最小路径依赖补丁，执行 `yanxu 包 锁 --离线 .` 与跨平台测试，再更新本表和生态调研。
