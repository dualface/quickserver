.. _admin:

Quick Server 内置管理接口使用
=============================

Quick Server 在安装完成了之后，默认配置了一些基于HTTP协议的接口，主要用于 Quick Server 服务器本身的管理、维护、以及配置。这些接口的实现代码都置于 ``source_root/apps/admin`` 下。

这些接口的 HTTP URL 都是 ``/admin`` 。

.. _monitor-interface:

监控接口
--------

监控接口是用于读取 Quick Server 监控数据的接口。Quick Server 的监控数据包括：进程CPU使用率，进程内存使用大小，进程接受的连接数。

.. _monitor-interface-getdata:

monitor.getdata
^^^^^^^^^^^^^^^

.. _monitor-interface-getdata-param:

参数
""""

    .. glossary::

        time_span
            *参数说明:*

                * 指定返回最近多少时间内的数据。 如果指定的时间跨度小于60s， 那么监控数据中就只会返回 ``last_60s`` 这一数组， 采样精度由 ``config.monitor.interval`` 决定； 如果指定的时间跨度大于60s， 但是小于1小时也就是3600s， 那么就只会返回 ``last_hour`` 这一数组， 精度为1分钟； 如果指定的时间间隔大于3600s， 那么只会返回 ``last_day`` 这一数组， 精度为1小时。
                * 该参数可以省略， 如果省略那么将会针对每一个进程的每一个监控项返回所有精度的数组。
                * 参数接受一个字符串。
                * 字符串格式由一组数字开始和一个时间描述字符组成。
                * 数字不包括小数点符号 "." ，也就是说只能是整数的字符串形式。
                * 时间描述符后缀可以是 "h", "m", "s" 或者它们的大写形式，分别用于表示小时，分钟以及秒。
                * 时间描述符后缀只能是上述一个字符，如果多个字符，只会取第一个。

            *参数格式 EBNF 描述:*

                .. productionlist:: time_span
                    time_span : number time_suffix
                    number : '0' | digit_excluding_zero {digit}
                    digit_excluding_zero : '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
                    digit : '0' | digit_excluding_zero
                    time_suffix : 'h' | 'm' | 's' | 'H' | 'M' | 'S'

            *参数举例:*

                * "1h" -- 表示一个小时。
                * "3600s" -- 表示3600秒，从时间上也等同于"1h"。
                * "5m" -- 表示5分钟。


.. _monitor-interface-format:

返回
""""

参数的返回是一个符合 JSON_ 格式的字符串，客户端应当尝试将其解析。

.. _JSON: http://json.org

    .. code-block:: lua
       :linenos:

        {
            "interval": 10,             -- 主机监控程序采样间隔， 即 config.monitor.interval 的值， 单位秒
            "cpu_cores": "2",           -- 主机 cpu 核心数量
            "mem_total": "2049988",     -- 主机物理内存，单位 kb
            "mem_free": "119988",       -- 主机空闲物理内存， 单位 kb
            "disk_total": "393838972",  -- 主机硬盘空间， 单位 kb
            "disk_free": "340386420",   -- 主机空闲磁盘空间， 单位 kb

            "NGINX_MASTER": {           -- 进程名称, nginx master 进程
                "cpu": {                -- 监控项目名称， 该项为 cpu 使用率
                                        -- 以下三种精度的数据， 在实际调用时， 只会根据 time_span 参数返回其一
                    "last_60s": [       -- 最近60s数据， 根据上述采样间隔采样
                        "0.2",
                        "0.2",
                        "0.2",
                        "0.2",
                    ],

                    "last_hour": [      -- 最近1小时数据， 1分钟间隔采样
                    ],

                    "last_day": [       -- 最近1天数据， 1小时间隔采样
                    ]
                },

                "mem": {                -- 监控项目， 当前进程的内容使用， 单位kb, 对于 beanstalkd 进程，没有该项
                                        -- 三种精度级别的数据， 根据 time_span 参数返回其一
                    "last_60s": [
                        "1952",
                        "1952",
                        "1960",
                        "1960",
                    ],

                    "last_hour": [
                    ],

                    "last_day" : [
                    ]
                },

                "conn_num": {           -- 监控项目， 当前进程接受的连接数, nginx worker 以及 beanstalkd 进程没有该项
                                        -- 三种精度级别的数据， 返回其一, 同上
                }
            },

            "NGINX_WORKER_#1": {        -- 进程名称， nginx worker 进程，有后缀数字区分不同的 worker 进程
                "cpu": {                -- 监控项目及数据， 同上， 没有 conn_num 项
                },

                "mem": {
                }
            },

            "REDIS-SERVER": {           -- 进程名称， redis server 进程
                "cpu": {                -- 监控项目及数据， 同 nginx master 进程
                },

                "mem": {
                },

                "conn_num": {
                }
            },

            "BEANSTALKD": {             -- 进程名称， beanstalkd 进程
                "cpu": {                -- 没有 mem 项， 以及 conn_num 项
                },

                "total_jobs": {         -- beanstalkd 进程， 有 total_jobs 项
                }
            }

        }

调用示例
""""""""

采用 ``curl`` 工具调用该接口的示例如下:

    .. code-block:: shell
       :linenos:

        curl "http://quick_server_host:port/admin?action=monitor.getdata&time_span=5s"
        curl "http://quick_server_host:port/admin" -d "action=monitor.getdata&time_span=5m"
        curl "http://quick_server_host:port/admin" -d '{"action" : "monitor.getdata", "time_span" : "5h"}

