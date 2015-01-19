# Quick-Server
## A Server Framework Based On OpenResty

---

## Latest Version 0.4.0

## Installation

### Install via Docker

1.  Install Docker. Please refer to https://www.docker.com/
2.  Run command: docker pull chukong/quick-server

> **NOTE** please refer this documents for more details: [Deploy Quick-Server with Docker] (https://github.com/dualface/quickserver/wiki/%E7%94%A8Docker%E9%83%A8%E7%BD%B2Quick-Server)

### Install via Shell Script

1.  Download codes from github or osc.

    github:
    https://github.com/dualface/quickserver.git

    OSChina mirror:
    https://git.oschina.net/cheerayhuang/quick-x-server.git

2.  Run shell script **install_ubuntu.sh** in root of codes dir.

> **NOTE** please refer this documents for more details: [Install Quick-Server on Linux with Shell](https://github.com/dualface/quickserver/wiki/%E5%9C%A8Linux%E4%B8%8B%E9%80%9A%E8%BF%87%E8%84%9A%E6%9C%AC%E5%AE%89%E8%A3%85Quick-Server)

## Links
-   [Quick-Server Wiki](https://github.com/dualface/quickserver/wiki)

-   [FAQ]()

-   [Install Quick-Server on Linux with Shell](https://github.com/dualface/quickserver/wiki/%E5%9C%A8Linux%E4%B8%8B%E9%80%9A%E8%BF%87%E8%84%9A%E6%9C%AC%E5%AE%89%E8%A3%85Quick-Server)

-   [Deploy Quick-Server with Docker](https://github.com/dualface/quickserver/wiki/%E7%94%A8docker%E9%83%A8%E7%BD%B2quick-server)

## Change Log

### 0.4.0
-   UPGRADE: From Openresty 1.7.2.x to 1.7.7.x.
-   IMPROVE: make install_ubunutu.sh better in order that user can install Quick-Server convenienty, and fix some bugs in it.
    -   create a symbol link for nginx, after Openresty installation.
    -   Add option "--no-check-certificate" for each "wget" command.
    -   "status\_quick\_server.sh" shell file should be copied to installation directory while installation is finished.
    -   Change those shell tools director, move them from  "/opt" to installation path.
    -   Add a new shell tool named "restart\_nginx\_only.sh" in order to restart nginx processes.
    -   Add a parameter for install_ubuntu.sh for specifying installation path insted of absolute path.
    -   Quick-Server configure files, including "redis.conf" and "nginx.conf", are modified automatically via "sed" tool.
-   FEATURE: Support plugin mechanism.
    -   Add some methods into "cc" framework, "load" and "bind" etc, for package file(lua file).
    -   Give two plugin examples: "Ranklist" and "ChatRoom", converted from "RanklistAction" and "ChatAction".
    -   Add simple functionality tests for above plugins.
-   IMPROVE: Add a demo action named "HelloworldAction"
    -   include a simple method "/sayhello" to show "hello world".
    -   there are two other methods "addandcount" and "sayletters" to show how to write a function with plugins.
    -   Add "helloworld" client which supports both html and websocket.
-   CHANGE: delete install_mac.sh. The installation of mac env will be supported in next version.
-   OTHER MINOR CHANGES:
    -   IMPROVE: upgrade Quick-Server wiki.
    -   BUGFIX: when deploying lua codes defined by user, the target directory in Quick-Server shoule be created.
    -   IMPROVE: The target directory in Quick-Server can be configured via "luaRepoPrefix" in config.lua for deploying lua codes defined by user.
    -   CHANGE: obsolete the old interface of uploading user codes.
    -   IMPROVE: Add two sql files: "base.sql" and "pre_condition.sql" in conf/sql for configuring MySql.
    -   CHANGE: don't need to set "root" privilege in nginx conf file.
    -   IMPROVE: Add README file for each sub-dir.
    -   CHANGE: change some shells which are used to encapsulate "nginx" command in "openresty/nginx".

> **NOTE** More change log please refer to https://github.com/dualface/quickserver/blob/master/CHANGELOG

