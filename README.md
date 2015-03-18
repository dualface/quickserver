# Quick-Server
## 基于OpenResty的服务器框架

---

## 最新版本 0.4.0

## 安装

### 通过Docker安装

1.  安装dcoker, 请参考 https://www.docker.com/ 。
2.  运行命令: *docker pull chukong/quick-server* 。

> **注意** 接下来的步骤请参考：[用Docker部署Quick-Server](https://github.com/dualface/quickserver/wiki/%E7%94%A8docker%E9%83%A8%E7%BD%B2quick-server)

### 通过Shell脚本安装

1.  从github或者OSChina下载quick-server源码：

    github:
    https://github.com/dualface/quickserver.git

    在OSChina有镜像仓库：
    https://git.oschina.net/cheerayhuang/quick-x-server.git

2.  在源码根目录下运行脚本 **install_ubuntu.sh**。

> **注意** 采用脚本安装方式，请自行在Ubuntu环境下安装MySql。

> **注意** 该脚本依赖于dpkg包管理，目前只支持Ubuntu环境，理论支持Debian，未作测试。

> **注意** 更加详细的内容请参考: [在Linux下通过脚本安装Quick Server
](https://github.com/dualface/quickserver/wiki/%E5%9C%A8Linux%E4%B8%8B%E9%80%9A%E8%BF%87%E8%84%9A%E6%9C%AC%E5%AE%89%E8%A3%85Quick-Server)

## 相关链接

-   [Quick-Server Wiki首页](https://github.com/dualface/quickserver/wiki)

    包括Quick-Server基本介绍，安装和使用。

-   [Quick-Server相关的常见问题]()

    包括Quick-Server的安装，使用中遇到的问题。

-   [在Linux下通过脚本安装Quick Server](https://github.com/dualface/quickserver/wiki/%E5%9C%A8Linux%E4%B8%8B%E9%80%9A%E8%BF%87%E8%84%9A%E6%9C%AC%E5%AE%89%E8%A3%85Quick-Server)

    在Ubuntu下使用命令行安装Quick-Server的过程。

-   [用Docker部署Quick-Server](https://github.com/dualface/quickserver/wiki/%E7%94%A8docker%E9%83%A8%E7%BD%B2quick-server)

    利用Docke直接下载容器安装Quick-Server。

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
    -  luasocket 升级到 3.0-rc1。
    -  增加了 luainspect 库。
