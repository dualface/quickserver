#!/bin/bash

function showHelp()
{
    echo "Usage: [sudo] ./stop_quick_server.sh [OPTIONS] [--reload]"
    echo "Options:" 
    echo -e "\t -a | --all \t\t stop nginx, redis and beanstalkd"
    echo -e "\t -n | --nginx \t\t stop nginx"
    echo -e "\t -r | --redis \t\t stop redis"
    echo -e "\t -b | --beanstalkd \t stop beanstalkd"
    echo -e "\t -h | --help \t\t show this help"
    echo "if the option is not specified, default option is \"--all(-a)\"."
    echo "please NOTICE that \"--reload\" swich can only be used with option \"--nginx(-n)\", or else it has no effect."
}

CURRDIR=$(dirname $(readlink -f $0))
NGINX_DIR=$CURRDIR/openresty/nginx/

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
if [ $NGINX -ne 1 ] ; then
    RELOAD=0
fi

#stop nginx
if [ $ALL -eq 1 ] || [ $NGINX -eq 1 ]; then
    if [ $RELOAD -eq 0 ] ; then
        nginx -p $(pwd) -c $NGINX_DIR/conf/nginx.conf -s stop
        echo "Stop Nginx DONE"
    else
        nginx -p $(pwd) -c $NGINX_DIR/conf/nginx.conf -s reload
        echo "Reload Nginx conf DONE" 
    fi
fi

#stop redis
if [ $ALL -eq 1 ] || [ $REDIS -eq 1 ]; then
    killall redis-server
    echo "Stop Redis DONE"
fi

#stop beanstalkd
if [ $ALL -eq 1 ] || [ $BEANS -eq 1 ]; then
    killall beanstalkd
    echo "Stop Beanstalkd DONE"
fi 

cd $CURRDIR
if [ $ALL -eq 1 ] ; then
    echo -e "\033[31mStop Quick Server DONE! \033[0m"
fi
