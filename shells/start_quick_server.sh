#!/bin/bash

function showHelp()
{
    echo "Usage: [sudo] ./start_quick_server.sh [OPTIONS]"
    echo "Options:"
    echo -e "\t -a , --all \t\t start nginx(release mode), redis and beanstalkd"
    echo -e "\t -n , --nginx \t\t start nginx in release mode"
    echo -e "\t -r , --redis \t\t start redis"
    echo -e "\t -b , --beanstalkd \t start beanstalkd"
    echo -e "\t -v , --version \t\t show Quick Server version"
    echo -e "\t -h , --help \t\t show this help"
    echo -e "\t      --debug \t\t start Quick Server in debug mode."
    echo "if the option is not specified, default option is \"--all(-a)\"."
    echo "In default, Quick Server will start in release mode, or else it will start in debug mode when you specified \"--debug\"."
}

function getVersion()
{
    LUABIN=$1/bin/openresty/luajit/bin/lua
    CODE='_C=require("conf.config"); print("Quick Server " .. _QUICK_SERVER_VERSION);'

    $LUABIN -e "$CODE"
}

function getNginxNumOfWorker()
{
    LUABIN=$1/bin/openresty/luajit/bin/lua
    CODE='_C=require("conf.config"); print(_C.numOfWorkers);'

    $LUABIN -e "$CODE"
}

function getNginxPort()
{
    LUABIN=$1/bin/openresty/luajit/bin/lua
    CODE='_C=require("conf.config"); print(_C.port);'

    $LUABIN -e "$CODE"
}

CURRDIR=$(dirname $(readlink -f $0))
OLDDIR=$(pwd)
NGINXDIR=$CURRDIR/bin/openresty/nginx
VERSION=$(getVersion $CURRDIR)

cd $CURRDIR

ARGS=$(getopt -o abrnvh --long all,nginx,redis,beanstalkd,debug,version,help -n 'Start quick server' -- "$@")

if [ $? != 0 ] ; then echo "Start Quick Server Terminating..." >&2; exit 1; fi

eval set -- "$ARGS"

declare -i DEBUG=0
declare -i ALL=0
declare -i BEANS=0
declare -i NGINX=0
declare -i REDIS=0
if [ $# -eq 1 ] ; then
    ALL=1
fi

if [ $# -eq 2 ] && [ $1 == "--debug" ]; then
    ALL=1
fi

while true ; do
    case "$1" in
        --debug)
            DEBUG=1
            shift
            ;;

        -a|--all)
            ALL=1
            shift
            ;;

        -b|--beanstalkd)
            BEANS=1
            shift
            ;;

        -r|--redis)
            REDIS=1
            shift
            ;;

        -n|--nginx)
            NGINX=1
            shift
            ;;

        -v|--version)
            echo $VERSION
            exit 0
            ;;

        -h|--help)
            showHelp;
            exit 0
            ;;

        --) shift; break ;;

        *)
            echo "invalid option: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[33mStart $VERSION... \033[0m"

echo "Start $VERSION... " >> $CURRDIR/logs/error.log

# start redis
if [ $ALL -eq 1 ] || [ $REDIS -eq 1 ]; then
    pgrep redis-server > /dev/null
    if [ $? -ne 0 ]; then
        $CURRDIR/bin/redis/bin/redis-server $CURRDIR/bin/redis/conf/redis.conf
        echo "Start Redis DONE"
    else
        echo "Redis is already started"
    fi
fi

# start beanstalkd
if [ $ALL -eq 1 ] || [ $BEANS -eq 1 ]; then
    pgrep beanstalkd > /dev/null
    if [ $? -ne 0 ]; then
        $CURRDIR/bin/beanstalkd/bin/beanstalkd > $CURRDIR/logs/beanstalkd.log &
        echo "Start Beanstalkd DONE"
    else
        echo "Beanstalkd is already started"
    fi
fi

# start nginx
if [ $ALL -eq 1 ] || [ $NGINX -eq 1 ]; then
    pgrep nginx > /dev/null
    if [ $? -ne 0 ]; then
        sed -i "/error_log/d" $NGINXDIR/conf/nginx.conf

        PORT=$(getNginxPort $CURRDIR)
        sed -i "s#listen [0-9]*#listen $PORT#g" $NGINXDIR/conf/nginx.conf

        NUMOFWORKERS=$(getNginxNumOfWorker $CURRDIR)
        sed -i "s#worker_processes [0-9]*#worker_processes $NUMOFWORKERS#g" $NGINXDIR/conf/nginx.conf

        if [ $DEBUG -eq 1 ] ; then
            sed -i "s#DEBUG = _DBG_ERROR#DEBUG = _DBG_DEBUG#g" $NGINXDIR/conf/nginx.conf
            sed -i "1a error_log logs/error.log debug;" $NGINXDIR/conf/nginx.conf
            sed -i "s#lua_code_cache on#lua_code_cache off#g" $NGINXDIR/conf/nginx.conf
            sed -i "s#DEBUG=_DBG_WARN#DEBUG=_DBG_DEBUG#g" $CURRDIR/tools.sh
        else
            sed -i "s#DEBUG = _DBG_DEBUG#DEBUG = _DBG_ERROR#g" $NGINXDIR/conf/nginx.conf
            sed -i "1a error_log logs/error.log;" $NGINXDIR/conf/nginx.conf
            sed -i "s#lua_code_cache off#lua_code_cache on#g" $NGINXDIR/conf/nginx.conf
            sed -i "s#DEBUG=_DBG_DEBUG#DEBUG=_DBG_WARN#g" $CURRDIR/tools.sh
        fi
        nginx -p $CURRDIR -c $NGINXDIR/conf/nginx.conf
        echo "Start Nginx DONE"
    else
        echo "Nginx is already started"
    fi
fi


cd $CURRDIR
if [ $ALL -eq 1 ]; then
    # start monitor
    pgrep tools.sh > /dev/null
    if [ $? -ne 0 ]; then
        $CURRDIR/tools.sh monitor.watch > $CURRDIR/logs/monitor.log &
    fi
    echo -e "\033[33mStart Quick Server DONE! \033[0m"
fi

sleep 1
$CURRDIR/status_quick_server.sh

cd $OLDDIR
