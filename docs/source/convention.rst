.. _convention:

文档约定
========

一些在文档中出现的名词，如无例外均是表示固定的含义。


.. glossary::

    quick_server_root
        表示 Quick Server 的安装路径。

    source_root
        表示 Quick Server 的源码路径。

    quick_server_host
        表示 Quick Server 所在的主机名字或者ip地址。

    config.lua
        表示 Quick Server 的配置文件，该文件在 ``quick_server_root/conf`` 下。文件本身是一个 lua 的 table。参考 :ref:`configuration_lua` 。

    config.item.subitem
        表示 Quick Server 的配置文件 ``config.lua`` 中的配置选项。

    install.sh
        位于源码根目录下的 Quick Server 安装脚本。参考 :ref:`install_by_shell_install_sh` 。

    start_quick_server.sh
        位于 ``quick_server_root/`` 下的 Quick Server 启动脚本。参考 :ref:`install_control_start_quick_server_sh`

    stop_quick_server.sh
        位于 ``quick_server_root/`` 下的 Quick Server 停止脚本。参考 :ref:`install_control_stop_quick_server_sh`

    status_quick_server.sh
        位于 ``quick_server_root/`` 下的 Quick Server 查看进程状态脚本。参考 :ref:`install_control_status_quick_server_sh`
