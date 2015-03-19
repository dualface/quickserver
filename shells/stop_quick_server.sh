#!/bin/bash

function showHelp()
{
    echo "Usage: [sudo] ./stop_quick_server.sh [OPTIONS] [--reload]"
    echo "Options:"
    echo -e "\t -a , --all \t\t stop nginx, redis and beanstalkd"
    echo -e "\t -n , --nginx \t\t stop nginx"
    echo -e "\t -r , --redis \t\t stop redis"
    echo -e "\t -b , --beanstalkd \t stop beanstalkd"
    echo -e "\t -h , --help \t\t show this help"
    echo -e "\t      --reload \t\t reload Quick Server config."
    echo "if the option is not specified, default option is \"--all(-a)\"."
}

function getNginxNumOfWorker()
{
    LUABIN=bin/openresty/luajit/bin/lua
    CODE='_C=require("conf.config"); print(_C.numOfWorkers);'

    $LUABIN -e "$CODE"
}

function getNginxPort()
{
    LUABIN=bin/openresty/luajit/bin/lua
    CODE='_C=require("conf.config"); print(_C.port);'

    $LUABIN -e "$CODE"
}

CURRDIR=$(dirname $(readlink -f $0))
NGINXDIR=$CURRDIR/bin/openresty/nginx/

ARGS=$(getopt -o abrnh --long all,nginx,redis,beanstalkd,reload,help -n 'Stop quick server' -- "$@")

if [ $? != 0 ] ; then echo "Stop Quick Server Terminating..." >&2; exit 1; fi

eval set -- "$ARGS"

declare -i RELOAD=0
declare -i ALL=0
declare -i BEANS=0
declare -i NGINX=0
declare -i REDIS=0
if [ $# -eq 1 ] ; then
    ALL=1
fi

while true ; do
    case "$1" in
        --reload)
            RELOAD=1
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

# "--reload" option has no effect on other options, except "--ngxin(-n)".
if [ $RELOAD -ne 0 ]; then
    ALL=0
fi

#stop nginx
if [ $ALL -eq 1 ] || [ $NGINX -eq 1 ] || [ $RELOAD -eq 1 ]; then
    if [ $RELOAD -eq 0 ] ; then
        pgrep nginx > /dev/null
        while [ $? -eq 0 ]
        do
            nginx -q -p $CURRDIR -c $NGINXDIR/conf/nginx.conf -s stop
            echo "Stop Nginx DONE"
            pgrep nginx > /dev/null
        done
    else
        PORT=$(getNginxPort)
        sed -i "s#listen [0-9]*#listen $PORT#g" $NGINXDIR/conf/nginx.conf

        NUMOFWORKERS=$(getNginxNumOfWorker)
        sed -i "s#worker_processes [0-9]*#worker_processes $NUMOFWORKERS#g" $NGINXDIR/conf/nginx.conf

        nginx -p $CURRDIR -c $NGINXDIR/conf/nginx.conf -s reload
        echo "Reload Nginx conf DONE"
    fi
fi

#stop redis
if [ $ALL -eq 1 ] || [ $REDIS -eq 1 ]; then
    killall redis-server 2> /dev/null
    echo "Stop Redis DONE"
fi

#stop beanstalkd
if [ $ALL -eq 1 ] || [ $BEANS -eq 1 ]; then
    killall beanstalkd 2> /dev/null
    echo "Stop Beanstalkd DONE"
fi

killall tools.sh 2> /dev/null
killall bin/openresty/luajit/bin/lua 2> /dev/null

if [ $RELOAD -ne 0 ]; then
    $CURRDIR/tools.sh monitor.watch > $CURRDIR/logs/monitor.log &
fi

cd $CURRDIR
if [ $ALL -eq 1 ] ; then
    echo -e "\033[31mStop Quick Server DONE! \033[0m"
fi

sleep 3
$CURRDIR/status_quick_server.sh
