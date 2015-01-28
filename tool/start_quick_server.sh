#!/bin/bash
CURRDIR=$(dirname $(readlink -f $0))
NGINXDIR=$CURRDIR/openresty/nginx/
DEBUG=nodebug

if [ $# -eq 0 ]; then
    ACTION=all
else
    if [ $1 == "--help" ] || [ $1 == "-h" ] ; then
        echo "Usage: [sudo] ./start_quick_server.sh [OPTIONS] [debug]"
        echo "Options:" 
        echo -e "\t all \t\t start nginx(release mode), redis and beanstalkd"
        echo -e "\t nginx \t\t start nginx in release mode"
        echo -e "\t redis \t\t start redis"
        echo -e "\t beanstalkd \t start beanstalkd"
        echo "if the option is not specified, default option is \"all\"."
        echo "In default, Quick Server will start in release mode, or else it will start in debug mode when you specified \"debug\" following options." 
        exit 1
    fi
    ACTION=$1
    if [ $# -ge 2 ]; then
        DEBUG=$2
    fi 
fi

#start nginx
if [ $ACTION == "all" ] || [ $ACTION == "nginx" ]; then
    sed -i "/error_log/d" $NGINXDIR/conf/nginx.conf
    if [ $DEBUG == "debug" ] ; then
        echo "Start Quick Server in DEBUG mode..."
        sed -i "1a error_log logs/error.log debug;" $NGINXDIR/conf/nginx.conf
    else
        sed -i "1a error_log logs/error.log;" $NGINXDIR/conf/nginx.conf
    fi
    nginx -p $(pwd) -c $NGINXDIR/conf/nginx.conf
fi

#start redis
if [ $ACTION == "all" ] || [ $ACTION == "redis" ]; then
    $CURRDIR/redis/bin/redis-server $CURRDIR/conf/redis.conf
fi

#start beanstalkd
if [ $ACTION == "all" ] || [ $ACTION == "beanstalkd" ]; then
    $CURRDIR/beanstalkd/bin/beanstalkd > $CURRDIR/logs/beanstalkd.log &
fi

cd $CURRDIR
echo "Start Quick Server DONE!"
