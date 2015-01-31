#!/bin/bash

function showHelp()
{
    echo "Usage: [sudo] ./start_quick_server.sh [OPTIONS] [--debug]"
    echo "Options:"
    echo -e "\t -a | --all \t\t start nginx(release mode), redis and beanstalkd"
    echo -e "\t -n | --nginx \t\t start nginx in release mode"
    echo -e "\t -r | --redis \t\t start redis"
    echo -e "\t -b | --beanstalkd \t start beanstalkd"
    echo -e "\t -h | --help \t\t show this help"
    echo "if the option is not specified, default option is \"--all(-a)\"."
    echo "In default, Quick Server will start in release mode, or else it will start in debug mode when you specified \"--debug\" following options.But NOTICE that \"--debug\" swich has no effect on other options except \"--all(-a)\" and \"--nginx(-n)\"."
}

CURRDIR=$(dirname $(readlink -f $0))
NGINXDIR=$CURRDIR/bin/openresty/nginx

ARGS=$(getopt -o abrnh --long all,nginx,redis,beanstalkd,debug,help -n 'Start quick server' -- "$@")

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

# "debug" option has no effect on other options, except "--all(-a)" and "--nginx(-n)".
if [ $NGINX -ne 1 ] && [ $ALL -ne 1 ]; then
    DEBUG=0
fi

#start redis
if [ $ALL -eq 1 ] || [ $REDIS -eq 1 ]; then
    $CURRDIR/bin/redis/bin/redis-server $CURRDIR/bin/redis/conf/redis.conf
    echo "Start Redis DONE"
fi

#start beanstalkd
if [ $ALL -eq 1 ] || [ $BEANS -eq 1 ]; then
    $CURRDIR/bin/beanstalkd/bin/beanstalkd > $CURRDIR/logs/beanstalkd.log &
    echo "Start Beanstalkd DONE"
fi

#start nginx
if [ $ALL -eq 1 ] || [ $NGINX -eq 1 ]; then
    sed -i "/error_log/d" $NGINXDIR/conf/nginx.conf
    if [ $DEBUG -eq 1 ] ; then
        #\033[41;37m [Beanstalkd] \033[0m
        echo -e "Start Nginx in \033[31m DEBUG \033[0m mode..."
        sed -i "1a error_log logs/error.log debug;" $NGINXDIR/conf/nginx.conf
        sed -i "s#lua_code_cache on#lua_code_cache off#g" $NGINXDIR/conf/nginx.conf
    else
        echo -e "Start Nginx in \033[31m RELEASE \033[0m mode..."
        sed -i "1a error_log logs/error.log;" $NGINXDIR/conf/nginx.conf
        sed -i "s#lua_code_cache off#lua_code_cache on#g" $NGINXDIR/conf/nginx.conf
    fi
    nginx -p $CURRDIR -c $NGINXDIR/conf/nginx.conf
    echo "Start Nginx DONE"
fi

cd $CURRDIR
if [ $ALL -eq 1 ]; then
    echo -e "\033[31mStart Quick Server DONE! \033[0m"
fi

sleep 1
$CURRDIR/status_quick_server.sh
