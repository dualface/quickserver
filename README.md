# Quick-Server
## 基于OpenResty的服务器框架

---

## 最新版本 0.5.0

## 介绍

Quick Server 为开发者提供一个稳定可靠，可伸缩的服务端架构，让开发者可以使用 Lua 脚本语言快速完成服务端的功能开发。

主要特征:

-   稳定可靠、经过验证的高性能游戏服务端架构。
-   使用 Lua 脚本语言开发服务端功能。
-   支持短连接和长连接，满足从异步网络到实时网络的各种需求。
-   支持插件机制，使用第三方插件加快功能开发。

更多介绍可以参考[Quick Server 介绍](http://quickserver-doc.rtfd.org/en/latest/intro.html)。

## 安装

安装 Quick Server 请参考[Quick Server 安装](http://quickserver-doc.readthedocs.org/en/latest/install.html)。

## 相关资源

-   [Quick-Server Wiki首页](http://quickserver-doc.readthedocs.org/en/latest/index.html)

    包括 Quick Server 的方方面面，基本介绍，安装和使用指南，源码分析等等。

-   [邮件列表]()

    敬请期待

-   支援邮件

    cheeray.huang#gmail.com

-   QQ群

    424776815

## 版本日志

### 0.5.0
-   重构了 Quick Server 几乎所有代码。
    -    全新的架构。从 ``ActionDispatcher`` 到各个连接基类，层次分明。
    -    引入插件机制。功能都会以插件包的形式提供和载入。
    -    重构了处理 HTTP 以及 WebSocket 请求的模块。
    -    重构了广播机制。实现了消息广播。
    -    调整了 Quick Server 的配置选项，更加简单易懂。
    -    新的管理和维护脚本工具。
    -    随时监控 Quick Server 进程状态，并以 web 页面展示。

-   改进了安装脚本以及安装过程。
    -    提供了唯一的安装脚本，替代原来按照发行版区分的多个安装脚本。
    -    除了基本的发行版包， Quick Server 的全部相关包都可以在离线状态下安装。没有网络延迟，节约时间。
    -    ``install.sh`` 脚本支持参数。比如用户可以设定安装路径。

-   提供了全新的基于 ``.rst`` 格式，并用 Sphinx 生成的文档。
    -   新的文档可以输出成多种文本格式，包括 html, pdf, latex 等等。
    -   新的文档输出命令简单，使用 make 工具即可。
    -   新文档从 0.5.0 开始，其 html 格式的版本会随着 Quick Server 发布。

-   升级了一些子模块。
    -  luasocket 升级到 3.0-rc1 版本。
    -  增加了 luainspect 库。
