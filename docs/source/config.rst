.. _configuration:

Quick Server 详细配置
=====================

Quick Server 的基本配置都可以由 ``config.lua`` 完成。除此之外，对于高级用户，Quick Server 并不反对直接修改 ``nginx.conf`` ， ``redis.conf`` 等配置文件, 但不建议。

    .. note::

        在一般情况下，直接编辑 ``nginx.conf`` 或者 ``redis.conf`` 总是不被建议的。如果要确定要直接编辑，请在编辑时自行保证与 ``config.lua`` 的兼容。


.. _configuration_lua:

config.lua 文件
---------------

``config.lua`` 文件本身是一个 Lua 的 table。table 中的每一个项目及其子项目都是 Quick Server 的配置项。

    .. glossary::

        appRootPath
            *参数说明*

                * lua string 类型。
                * 配置用户的 app 根目录。
                * 是一个绝对路径。

            *参数格式 EBNF 描述*

                .. productionlist:: appRootPath
                    appRootPath : {dir} ;
                    dir : '/' | '/', {char} ;
                    char : ? all available char ? ;

                .. note::

                    上述 EBNF 中的非终结符 ``char`` 是指所有的可用于操作系统命名的字符，限于篇幅，这里不再将它的规则列出，下同。

        appWorkers.instances
            *参数说明*

                * lua number 类型。
                * 配置 nginx worker 数量。

            *参数格式 EBNF 描述*

                .. productionlist:: appWorkers.instances
                    appWorkers.instances : digit_excluding_zero {digit} ;
                    digit_excluding_zero : '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;
                    digit : '0' | digit_excluding_zero ;

            *默认值*

                4

        appHttpMessageFormat
            *参数说明*

                * lua string 类型。
                * 配置 Http 协议数据格式。
                * 可选值为：

                  * json， 以 JSON 格式封装数据包。
                  * text， 以纯文本格式封装数据包。

            *参数格式 EBNF 描述*

                .. productionlist:: appHttpMessageFormat
                    appHttpMessageFormat : 'json' | 'text' ;

            *默认值*

                "json"

        appSocketMessageFormat
            *参数说明*

                * lua string 类型。
                * 配置 WebSocket 协议数据格式。
                * 可选值为：

                  * json， 以 JSON 格式封装数据包。
                  * text， 以纯文本格式封装数据包。

            *参数格式 EBNF 描述*

                .. productionlist:: appSocketMessageFormat
                    appSocketMessageFormat : 'json' | 'text' ;

            *默认值*

                "json"

        appJobMessageFormat
            *参数说明*

                * lua string 类型。
                * 配置 Beanstalkd 的队列中存储的 Job 的数据格式。
                * 可选值为：

                  * json， 以 JSON 格式封装数据包。
                  * text， 以纯文本格式封装数据包。

            *参数格式 EBNF 描述*

                .. productionlist:: appJobMessageFormat
                    appJobMessageFormat : 'json' | 'text' ;

            *默认值*

                "json"

        quickserverRootPath
            *参数说明*

                * lua string 类型。
                * 配置 Quick Server 安装路径。
                * 是一个绝对路径。
                * 用户不能直接修改，由 ``install.sh`` 脚本自动生成。

            *参数格式 EBNF 描述*

                .. productionlist:: quickserverRootPath
                    quickserverRootPath : {dir} ;
                    dir : '/' | '/', {char} ;
                    char : ? all available char ? ;

        port
            *参数说明*

                * lua number 类型。
                * 配置 Quick Server 监听端口。

            *参数格式 EBNF 描述*

                .. productionlist:: port
                    port : digit_excluding_zero {digit} ;
                    digit_excluding_zero : '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;
                    digit : '0' | digit_excluding_zero ;

            *默认值*

                8088

        welcomeEnabled
            *参数说明*

              * lua boolean 类型。
              * 配置是否运行 Quick Server 自带的 welcome demo。

            *参数格式 EBNF 描述*

                .. productionlist:: welcomeEnabled
                    welcomeEnabled : true | false ;

            *默认值*

                true

        adminEnabled
            *参数说明*

              * lua boolean 类型。
              * 配置是否打开 Quick Server 的 admin 接口。包括了获取监控数据等子接口。

            *参数格式 EBNF 描述*

                .. productionlist:: adminEnabled
                    adminEnabled : true | false ;

            *默认值*

                true

        websocketsTimeout
            *参数说明*

              * lua number 类型。
              * 配置 WebSocket 协议超时时间, 单位毫秒 。

            *参数格式 EBNF 描述*

                .. productionlist:: websocketsTimeout
                    websocketsTimeout : numeral | numeral op numeral ;
                    op : '+' | '-' | '*' | '/' | '%' ;
                    numeral : digit_excluding_zero {digit} ;
                    digit_excluding_zero : '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;
                    digit : '0' | digit_excluding_zero ;

            *默认值*

                60 * 1000

        websocketMaxPayloadLen
            *参数说明*

              * lua number 类型。
              * 配置 WebSocket 协议数据包最大值， 单位 byte。

            *参数格式 EBNF 描述*

                .. productionlist:: websocketMaxPayloadLen
                    websocketMaxPayloadLen : numeral | numeral op numeral ;
                    op : '+' | '-' | '*' | '/' | '%' ;
                    numeral : digit_excluding_zero {digit} ;
                    digit_excluding_zero : '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;
                    digit : '0' | digit_excluding_zero ;

            *默认值*

                16 * 1024

        maxSubscribeRetryCount

            *参数说明*

              * lua number 类型。
              * 配置订阅广播频道最大尝试次数。

            *参数格式 EBNF 描述*

                .. productionlist:: maxSubscribeRetryCount
                    maxSubscribeRetryCount : digit_excluding_zero {digit} ;
                    digit_excluding_zero : '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;
                    digit : '0' | digit_excluding_zero ;

            *默认值*

                10

        redis.socket
            *参数说明*

              * lua string 类型。
              * 配置 unix domain socket 协议文件路径。该配置存在时，Redis 协议采用 unix domain socket。
              * 是一个绝对路径。
              * 不建议用户直接修改， 由 ``install.sh`` 脚本生成。

              .. note::

                如果用户修改这个值，请自行保证与 ``redis.conf`` 相关配置的兼容。

            *参数格式 EBNF 描述*

                .. productionlist:: redis.socket
                    redis.socket : 'unix:', {dir}, socket_file ;
                    dir : '/' | '/', {char} ;
                    socket_file : '/', char, {char}, '.sock' ;


        redis.host
            *参数说明*

              * lua string 类型。
              * 配置 redis-server 的主机名。这个参数与上面的 ``redis.socket`` 互斥。当这个参数被设置时， redis 采用 tcp socket 连接。

            *参数格式 EBNF 描述*

                .. productionlist:: redis.host
                    redis.host : ip ;
                    ip : (* see ip specification for ipv4 and ipv6 *) ;

                .. note::

                    ip 地址的定义请参考 `ipv4 RFC`_ 以及 `ipv6 RFC`_ 。下同。

.. _ipv4 RFC: http://http://tools.ietf.org/html/rfc791
.. _ipv6 RFC: http://tools.ietf.org/html/rfc2460

            *默认值*

                "127.0.0.1"

        redis.port
            *参数说明*

              * lua number 类型。
              * 配置 redis-server 的端口。这个参数与上面的 ``redis.socket`` 互斥。当这个参数被设置时， redis 采用 tcp socket 连接。

            *参数格式 EBNF 描述*

                .. productionlist:: redis.port
                    redis.port : digit_excluding_zero {digit} ;
                    digit_excluding_zero : '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;
                    digit : '0' | digit_excluding_zero ;

            *默认值*

                6379

        beanstalkd.host
            *参数说明*

              * lua string 类型。
              * 配置 Beanstalkd 的服务器主机名。

            *参数格式 EBNF 描述*

                .. productionlist:: beanstalkd.host
                    beanstalkd.host : ip ;
                    ip : (* see ip specification for ipv4 and ipv6 *) ;

            *默认值*

                "127.0.0.1"

        beanstalkd.port
            *参数说明*

              * lua number 类型。
              * 配置 Beanstalkd 的服务器主机端口。

            *参数格式 EBNF 描述*

                .. productionlist:: beanstalkd.port
                    beanstalkd.port : digit_excluding_zero {digit} ;
                    digit_excluding_zero : '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;
                    digit : '0' | digit_excluding_zero ;


            *默认值*

                11300

        beanstalkd.jobTube
            *参数说明*

                * lua string 类型。
                * 配置 beanstalkd 任务队列名称。

            *参数格式 EBNF 描述*

                .. productionlist:: beanstalkd.jobTube
                    beanstalkd.jobTube : alpha_char, { alpha_char | digit } ;
                    alpha_char : ? all letters, case-insensitive ? ;
                    digit : '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;

            *默认值*

                "jobTube"

        monitor.process
            *参数说明*

                * lua table 类型。
                * 配置 monitor 的监听对象进程名称。

            *参数格式 EBNF 描述*

                .. productionlist:: monitor.process
                    monitor.process : table_constructor ;

                .. note::

                    上述 EBNF 中的非终结符 ``table_constructor`` 的产生规则，可以参考 `lua 手册`_ 中 ``Lua 的完整语法`` 一节中 ``tableconstructor`` 的产生规则。

.. _lua 手册: http://cloudwu.github.io/lua53doc/manual.html#9

            *默认值*

                .. code-block:: lua

                    {
                        "nginx",
                        "redis-server",
                        "beanstalkd",
                    }

        monitor.interval
            *参数说明*

                * lua number 类型。
                * 配置 monitor 监控频率， 单位秒。

            *参数格式 EBNF 描述*

                .. productionlist:: monitor.interval
                    monitor.interval : numeral | numeral op numeral ;
                    op : '+' | '-' | '*' | '/' | '%' ;
                    numeral : digit_excluding_zero {digit} ;
                    digit_excluding_zero : '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;
                    digit : '0' | digit_excluding_zero ;

            *默认值*

                2


.. _configuration_senior:

高级配置
--------

.. _configuration_senior_nginx_conf:

nginx.conf 文件
^^^^^^^^^^^^^^^

.. _configuration_senior_redis_conf:

redis.conf 文件
^^^^^^^^^^^^^^^
