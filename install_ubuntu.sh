#!/bin/bash

if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

if [ $# -ne 1 ]; then
    DEST_DIR=/opt/quick_server
else
    if [ $1 == "--help" ] || [ $1 == "-h" ] ; then
        echo "Usage: ./install_ubuntu.sh [absolute path for installation]"
        echo "if the path is not specified, default path is /opt/quick_server."
        exit 1
    fi
    DEST_DIR=$1
fi

set -e

apt-get install -y build-essential libpcre3-dev libssl-dev git-core unzip

CUR_DIR=$(dirname $(readlink -f $0))
BUILD_DIR=/tmp/install_quick_server

OPENRESTY_VER=1.7.7.1
REDIS_VAR=2.6.16
BEANSTALKD_VER=1.9


cd ~
rm -fr $BUILD_DIR
mkdir -p $BUILD_DIR
cp -f $CUR_DIR/install/*.tar.gz $BUILD_DIR

mkdir -p $DEST_DIR
mkdir -p $DEST_DIR/redis/bin
mkdir -p $DEST_DIR/beanstalkd/bin
mkdir -p $DEST_DIR/logs
mkdir -p $DEST_DIR/tmp
mkdir -p $DEST_DIR/conf
mkdir -p $DEST_DIR/openresty

# install openresty
cd $BUILD_DIR
tar zxf ngx_openresty-$OPENRESTY_VER.tar.gz
cd ngx_openresty-$OPENRESTY_VER

./configure --prefix=$DEST_DIR/openresty --with-luajit
make
make install

# install quick server framework
ln -f -s $DEST_DIR/openresty/luajit/bin/luajit-2.1.0-alpha /usr/bin/lua
ln -f -s $DEST_DIR/openresty/luajit/bin/luajit-2.1.0-alpha $DEST_DIR/openresty/luajit/bin/lua
cp -rf $CUR_DIR/src $DEST_DIR
cd $CUR_DIR/tool/

#deploy tool script
cp start_quick_server.sh stop_quick_server.sh status_quick_server.sh $DEST_DIR -f
ln -f -s $DEST_DIR/openresty/nginx/sbin/nginx /usr/bin/nginx

#copy nginx and redis conf file
cp $CUR_DIR/conf/nginx.conf $DEST_DIR/openresty/nginx/conf/. -f
cp $CUR_DIR/conf/redis.conf $DEST_DIR/conf/. -f
sed -i "s#/opt/quick_server#$DEST_DIR#g" $DEST_DIR/openresty/nginx/conf/nginx.conf
sed -i "s#/opt/quick_server#$DEST_DIR#g" $DEST_DIR/conf/redis.conf
mkdir -p $DEST_DIR/redis/rdb

#install luasocket
cd $BUILD_DIR
tar zxf luasocket.tar.gz
cp -rf socket $DEST_DIR/openresty/luajit/lib/lua/5.1/.
cp -f socket.lua $DEST_DIR/openresty/luajit/share/lua/5.1/.

#install cjson
cd $BUILD_DIR
tar zxf cjson.tar.gz
cp cjson.so $DEST_DIR/openresty/luajit/lib/lua/5.1/.

# install redis
cd $BUILD_DIR
tar zxf redis-$REDIS_VAR.tar.gz
cd redis-$REDIS_VAR
make
cp src/redis-server $DEST_DIR/redis/bin
cp src/redis-cli $DEST_DIR/redis/bin
cp src/redis-sentinel $DEST_DIR/redis/bin
cp src/redis-benchmark $DEST_DIR/redis/bin
cp src/redis-check-aof $DEST_DIR/redis/bin
cp src/redis-check-dump $DEST_DIR/redis/bin

# install beanstalkd
cd $BUILD_DIR
tar zxf beanstalkd-$BEANSTALKD_VER.tar.gz
cd beanstalkd-$BEANSTALKD_VER
make
cp beanstalkd $DEST_DIR/beanstalkd/bin


# done

echo ""
echo ""
echo ""
echo "DONE!"
echo ""
echo ""
