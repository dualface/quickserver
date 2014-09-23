# Quick-Server
## 基于OpenResty的服务器框架

---

## 最新版本 0.3.7

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

### 0.3.7
- 实现用户登录功能，与cocoachina网站平台对接。
- 加入了Session ID验证机制，每一次http接口调用都会进行Session ID验证了。每一次基于WebSocket的访问，在第一次调用接口时，都会进行Session ID验证。
- 改进了用户自定义代码功能，原来的/user/codes接口将被/_server/user/uploadcodes接口替代。也就是说，现在的用户自定义代码功能是属于Quick-Server自带的一个内部服务。*/user/codes 接口在这一版本还可以使用，但不推荐，将在下一版本正式废弃*。
- 其他改进与bug修复：
   - 修正了Quick-Server中http库和url库的载入问题。
   - 在nginx.conf中添加了DNS服务器地址配置。
   - 为Quick-Server新添加了一个脚本工具"status\_quick\_server.sh"，可以简单的查看Quick-Server各进程状态。
   - 增加了两个函数释放MySql以及Redis链接。现在每个http请求以及通过WebSocket的调用，在结束后都会主动释放连接。
   - server/config.lua文件在安装后不再会是字节码的形式，而保留lua源码，方便用户配置。
   - 修改了tool/compile_bytes.sh中的luajit版本号。现在的luajit版本是luajit-2.1.0-alpha，对应于OpenResty1.7.2。
   - Ranklist.Add接口中的参数"value"可以使用string呈现。
   - Store.Saveobj接口现在返回的id不会再带有"/"符号，而是用"-"代替，方便字符串处理。

### 0.3.6

- 更新OpenResty到1.7.2版本。 
- 除了使用HTTP协议，现在也可以使用WebSocket协议访问用户自定义的代码了。
- 修正了索引维护脚本代码里LUA_PATH路径。
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





