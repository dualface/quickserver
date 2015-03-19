# Quick Server
## 基于OpenResty的服务器框架

---

## 最新版本 0.5.0

## 介绍

Quick Server 为开发者提供一个稳定可靠，可伸缩的服务端架构，让开发者可以使用 Lua 脚本语言快速完成服务端的功能开发。

<<<<<<< HEAD
> **注意** 接下来的步骤请参考：[用 Docker 部署 Quick Server](https://github.com/dualface/quickserver/wiki/%E7%94%A8-Docker-%E9%83%A8%E7%BD%B2-Quick-Server)
=======
主要特征:
>>>>>>> develop

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

<<<<<<< HEAD
> **注意** 更加详细的内容请参考: [在 Linux 下通过脚本安装 Quick Server](https://github.com/dualface/quickserver/wiki/%E5%9C%A8-Linux-%E4%B8%8B%E9%80%9A%E8%BF%87%E8%84%9A%E6%9C%AC%E5%AE%89%E8%A3%85-Quick-Server)
=======
-   [邮件列表]()
>>>>>>> develop

    敬请期待

<<<<<<< HEAD
-   [Quick Server Wiki 首页](https://github.com/dualface/quickserver/wiki)
  
    包括Quick-Server基本介绍，安装和使用。

-   [Quick Server 相关的常见问题]()

    包括Quick-Server的安装，使用中遇到的问题。
  
-   [在 Linux 下通过脚本安装 Quick Server](https://github.com/dualface/quickserver/wiki/%E5%9C%A8-Linux-%E4%B8%8B%E9%80%9A%E8%BF%87%E8%84%9A%E6%9C%AC%E5%AE%89%E8%A3%85-Quick-Server)
  
    在 Linux 下使用命令行安装Quick-Server的过程。

-   [用 Docker 部署 Quick Server](https://github.com/dualface/quickserver/wiki/%E7%94%A8-Docker-%E9%83%A8%E7%BD%B2-Quick-Server)
  
    利用Docke直接下载容器安装Quick-Server。

## 版本日志

### 0.4.0
-   升级Openresty到1.7.7.x版本。
-   修改了安装脚本install_ubuntu.sh，让用户使用起来更简单。并修正了一些bug。
    -   现在安装Openresty结束之后，会自动帮助用户在"/usr/bin"下创建一个nginx的软链接。
    -   所有的"wget"命令都加入了"--no-check-certificate"选项，避免检查证书时带来验证不过而无法下载的问题。
    -   "status\_quick_server.sh"会在安装完成后拷贝到Quick-Server安装目录下。
    -   所有的工具脚本，现在都从"/opt"目录下移动到了Quick-Server的安装目录下。
    -   增加了一个工具脚本"restart\_nginx_only.sh"。
    -   install_ubuntu.sh现在可以接收一个参数，用于指定安装目录。
    -   与Quick-Server相关的configure文件，现在会在install_ubuntu.sh脚本中被自动修改：）
-   支持插件机制。
    -   给框架增加了一些方法，"load"，"bind"等等，用于支持载入插件。
    -   提供了两个插件的例子："RanklistAction"和"ChatAction"。
    -   提供了简单的测试，可以让用户测试并且了解如何使用插件。
-   完善了"Helloworld"的Demo。
    -   包含了一个"SayHello"方法用于显示"helloworld earth"。
    -   增加两个方法用于调用插件，简单展示如何利用插件机制来完成代码逻辑。
    -   在"/test"下的客户端脚本支持WebSocket以及Html两种协议访问demo。
-   删除了install_mac.sh脚本，mac环境下的安装将在后续的版本支持。
-   其他改动：
    -   更新了 Quick-Server wiki。
    -   修复了一个运行用户自定义lua代码的bug，当部署用户代码时，Quick-Server应当首先创建目标目录。
    -   现在用户代码在Quick-Server中的目标目录不一定是在"openresty/server/"下了，可以通过"openresty/server/config.lua"中的"luaRepoPrefix"配置到"openresty"下的任何目录。
    -   废弃了之前的上传用户自定义lua代码的接口。
    -   增加了一个pre_condition.sql文件，并把sql文件都移到了源码目录"conf/sql"下, 方便用户在使用的时候快速配置MySql。
    -   在nginx.conf中，不需要再设置nginx的用户为"root"。
    -   为每一个源代码目录下的子目录增加了README.md文件。
    -   修改了一些在"openresty/nginx/"下的对命令"nginix"封装的脚本。

> **注意** 完整的版本日志信息可以参考 [Quick Server 安装以及版本信息](https://github.com/dualface/quickserver/wiki/Quick-Server-%E5%AE%89%E8%A3%85%E4%BB%A5%E5%8F%8A%E7%89%88%E6%9C%AC%E4%BF%A1%E6%81%AF)
=======
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
>>>>>>> develop
