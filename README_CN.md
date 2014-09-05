# Quick-Server
## 基于OpenResty的服务器框架

---

## 最新版本 0.3.6

## 安装

### 通过Docker安装

1. 安装dcoker, 请参考 https://www.docker.com/ 。
2. 运行命令: *docker pull chukong/quick-server* 。

### 通过Shell脚本安装

1. 从github或者OSChina下载quick-server源码：

   github:
   https://github.com/dualface/quickserver.git

   在OSChina有镜像仓库：
   https://git.oschina.net/cheerayhuang/quick-x-server.git

2. 在源码根目录下运行脚本 **install_ubuntu.sh**。

## 版本日志

### 0.3.6

- 更新OpenResty到1.7.2版本。 
- 除了使用HTTP协议，现在也可以使用WebSocket协议访问用户自定义的代码了。
- 基于github的wiki完善了中文Quick-Server Wiki文档。
- Quick-Server现在基于Docker发布的是lua字节码。并且修改ubuntu下的安装脚本，更正了一些安装错误。

### 0.3.5

- 调整了项目的目录结构，使得部署后的quick-server安装目录更加简洁。
- 集成了lua-resty-http库，现在可以使用cc.server.http或者cc.server.url来调用这个库了。
- 修正了一些nginx.conf中的设置。

### 0.3.1
- 修复bug: 现在，在用户自定义代码的目录结构中一定要有"actions"子目录。 
- 修复bug: 允许http的返回值除了JSON格式的表，还可以是一个字符串。
- 改进： 支持http接口的uri不区分大小写。

### 0.3.0
- 用户自定义功能改进，支持更灵活的用户自定义代码结构，比如子目录。

### 0.2.0
- 通过让用户自己上传lua代码的方式，支持用户自定义功能。
- 除了WebSocket之外，支持http协议调用功能接口。
- 除了使用shell脚本，用户还可以选择Docker这种新的安装方式。

### 0.1.0
- 基于mysql 5以及JSON格式，支持简单的对象存储。
- 在对象存储中支持索引。
- 基于Redis实现了排行榜功能。
- 所有的功能接口都基于WebSocket。





