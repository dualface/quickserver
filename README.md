# Quick-Server
## 基于OpenResty的服务器框架

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

> **注意** 完整的版本日志信息可以参考 [Quick-Server安装以及版本信息](https://github.com/dualface/quickserver/wiki/Quick-Server%E5%AE%89%E8%A3%85%E4%BB%A5%E5%8F%8A%E7%89%88%E6%9C%AC%E4%BF%A1%E6%81%AF)
