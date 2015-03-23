.. _install:

Quick Server 安装
=================

Quick Server 安装和部署可以使用两种方式。

一种方式是下载 Quick Server 源代码，然后使用 shell 脚本进行安装。

还有一种方式是用户直接使用我们提供的 Linux 虚拟机， 在个人电脑上运行。这种方式往往用于快速部署 Quick Server 的开发环境。

.. _install_by_shell:

使用脚本安装
-------------

.. _install_by_shell_download_code:

下载 Quick Server 代码
^^^^^^^^^^^^^^^^^^^^^^^

首先，我们需要下载 Quick Server 代码。我们可以使用 Git 直接从 Quick Server 的代码仓库拉取。

    .. code-block:: shell

        git clone git@github.com:dualface/quickserver.git

我们假设源代码放在 ``~/qs`` 下。


.. _install_by_shell_install_sh:

运行 install.sh 脚本
^^^^^^^^^^^^^^^^^^^^^

从 Quick Server 0.5.0 版本开始，提供了统一的一站式安装脚本 **install.sh** ，新的脚本不再根据包管理器是 ``yum`` 或者 ``dpkg`` 来区分系统;除了 Linux 的基本组件，不再需要联网安装 Quick Server 的组件。

    .. warning::

        不区分 ``yum`` 以及 ``dpkg`` 意味着支持绝大多数 Linux 发行版， 包括但不限于 CentOS 以及 Ubuntu，但是该脚本仅在 CentOS 以及 Ubuntu 下测试通过。

``install.sh`` 脚本支持一些参数:

    --prefix=arg        指定 Quick Server 的安装路径。默认路径是 ``/opt/quick_server`` 。
    -a, --all           安装 Quick Server 所有基本组件, 包括 nginx(OpenResty), Quick Server Framework, Redis, 以及 Beanstalkd。这是 ``install.sh`` 的默认选项。
    -n, --nginx         仅安装 nginx(OpenResty) 以及 Quick Server Framework。
    -r, --redis         仅安装 Redis。
    -b, --beanstalkd    仅安装 Beanstalkd。
    -h, --help          显示参数帮助。

我们现在执行脚本把 Quick Server 安装到 ``/opt/qs`` 目录下：
    .. code-block:: shell

        # 进入 Quick Server 源代码目录
        cd ~/qs

        # 执行 install.sh 脚本
        sudo ./install.sh -a --prefix=/opt/qs

    .. note::

        执行 ``install.sh`` 脚本，务必使用 ``sudo`` 获得 ``root`` 权限。否则脚本将会给出错误提示信息。

    .. seealso::

        笔者的安装环境如下， 用户可以自行参考:

            :NAME: Ubuntu
            :VERSION: 14.04, Trusty Tahr
            :ID: ubuntu
            :ID_LIKE: debian
            :PRETTY_NAME: Ubuntu 14.04 LTS


        以上的信息可以通过查看 ``/etc/os-release`` 获得:

            .. code-block:: shell

                cat /etc/os-release

        笔者的安装环境内核为 ``3.13.0-24-generic`` 。内核信息可以使用如下命令获得:

            .. code-block:: shell

                uname -r

好了，现在你只需要泡上一杯茶，等待 "DONE" 出现在屏幕上，这表示安装已经完成了：）

.. _install_by_vm:

使用虚拟机
----------

    -Coming Soon-

.. _install_config:

Quick Server 配置
-----------------

Quick Server 的基本配置是通过 ``config.lua`` 完成的。在本文的安装例子中，这个文件放在 ``/opt/qs/conf`` 下。

在一般情况下，这个文件不需要过多配置，Quick Server 的配置教程请参考 :ref:`configuration` 。

.. _install_control:

Quick Server 启动与停止
-----------------------

Quick Server 的启动，停止以及进程状态查看是通过 ``start_quick_server.sh`` ， ``stop_quick_server.sh`` 以及 ``status_quick_server.sh`` 完成的。 在本文的安装例子中，这3个脚本都位于 ``/opt/qs`` 目录下。

.. _install_control_start_quick_server_sh:

start_quick_server.sh 脚本
^^^^^^^^^^^^^^^^^^^^^^^^^^^

``start_quick_server.sh`` 脚本支持如下的参数：

    --debug             以调试模式启动 Quick Server。
    -a, --all           启动 Quick Server 所有基本组件, 包括 nginx(OpenResty), Quick Server Framework, Redis, 以及 Beanstalkd。这是 ``start_quick_server.sh`` 的默认选项。
    -n, --nginx         仅启动 nginx(OpenResty) 以及 Quick Server Framework。
    -r, --redis         仅启动 Redis。
    -b, --beanstalkd    仅启动 Beanstalkd。
    -h, --help          显示参数帮助。

我们可以执行这个脚本来启动 Quick Server。

    .. code-block:: shell

        sudo /opt/qs/start_quick_server.sh

    .. note::

        执行 ``start_quick_server.sh`` 脚本，务必使用 ``sudo`` 获得 ``root`` 权限。否则脚本将会给出错误，并且不能正常启动 Quick Server。


如果要以调试模式来启动 Quick Server，可以这样：

    .. code-block:: shell

        sudo /opt/qs/start_quick_server.sh --debug

.. _install_control_stop_quick_server_sh:

stop_quick_server.sh 脚本
^^^^^^^^^^^^^^^^^^^^^^^^^

``stop_quick_server.sh`` 脚本支持如下的参数：

    --reload            向 nginx 进程发送 SIGHUP 信号，用于重新载入配置，重启 nginx 的 worker 进程。该选项仅在 ``-n`` 或者 ``--nginx`` 被指定时有效。
    -a, --all           停止 Quick Server 所有基本组件, 包括 nginx(OpenResty), Quick Server Framework, Redis, 以及 Beanstalkd。这是 ``stop_quick_server.sh`` 的默认选项。
    -n, --nginx         仅停止 nginx(OpenResty) 以及 Quick Server Framework。
    -r, --redis         仅停止 Redis。
    -b, --beanstalkd    仅停止 Beanstalkd。
    -h, --help          显示参数帮助。

我们可以执行这个脚本来停止 Quick Server。

    .. code-block:: shell

        sudo /opt/qs/stop_quick_server.sh

    .. note::

        执行 ``stop_quick_server.sh`` 脚本，务必使用 ``sudo`` 获得 ``root`` 权限。否则脚本将会给出错误，并且不能正常停止 Quick Server。

如果要 nginx 重新载入 nginx 的配置，并重启 nginx 的 worker 进程，可以这样使用：

    .. code-block:: shell

        sudo /opt/qs/stop_quick_server.sh -n --reload

    .. note::

        值得注意的是， ``--reload`` 并不是重新载入 ``config.lua`` ，而仅仅是重新载入 nginx 的配置文件 ``nginx.conf`` ，并重启所有的 nginx worker 进程，nginx master 并不会重启。

.. _install_control_status_quick_server_sh:

status_quick_server.sh 脚本
^^^^^^^^^^^^^^^^^^^^^^^^^^^

``status_quick_server.sh`` 脚本用于查看与 Quick Server 相关的进程。直接使用它就可以了：

    .. code-block:: shell

        /opt/qs/status_quick_server.sh

终端会将结果以多个 section 的方式返回，包括 ``[Nginx]`` ， ``[Redis]`` ， ``[Beanstalkd]`` 以及 ``[Monitor]`` 。每一个 section 下包含了各自相关的进程。

    .. note::

        只要是以默认的 ``-a`` 或者 ``--all`` 方式启动 Quick Server，那么所有的 section 下都应该看到有进程在运行。如果以其他选项启动了 Quick Server 的部分组件，那么只会看到部分组件的进程在运行，并且 ``[Monitor]`` 下不会有进程运行，也就是在这种情况下， Monitor 不会启动。
