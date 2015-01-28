#!/bin/bash

CURRDIR=$(dirname $(readlink -f $0))
NGINX_DIR=$CURRDIR/openresty/nginx/

if [ $# -ne 1 ]; then
    ACTION=all
else
    if [ $1 == "--help" ] || [ $1 == "-h" ] ; then
        echo "Usage: [sudo] ./stop_quick_server.sh [OPTIONS]"
        echo "Options:" 
        echo -e "\t all \t\t stop nginx, redis and beanstalkd"
        echo -e "\t nginx \t\t stop nginx"
        echo -e "\t redis \t\t stop redis"
        echo -e "\t beanstalkd \t stop beanstalkd"
        echo "if the param is not specified, default option is \"all\"."
        exit 1
    fi
    ACTION=$1 
fi

#start nginx
if [ $ACTION == "all" ] || [ $ACTION == "nginx" ]; then
    nginx -p $(pwd) -c $NGINX_DIR/conf/nginx.conf -s stop
fi

#start redis
if [ $ACTION == "all" ] || [ $ACTION == "redis" ]; then
    PID=$(ps -ef | grep "redis" | awk '{print $2}')
    kill -9 $PID
fi

#start beanstalkd
if [ $ACTION == "all" ] || [ $ACTION == "beanstalkd" ]; then
    PID=$(ps -ef | grep "beanstalkd" | awk '{print $2}')
    kill -9 $PID
fi 

cd $CURRDIR
echo "Quick Server is Stopped!"
