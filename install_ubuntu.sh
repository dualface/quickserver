#!/bin/bash

if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

set -e

apt-get install -y build-essential libpcre3-dev git-core unzip

CUR_DIR=$(pwd)
DEST_DIR=/opt/quick_server
BUILD_DIR=/tmp/install_quick_server
THIRD_PARTY_DIR=$DEST_DIR/third_party

OPENRESTY_VER=1.7.2.1
LUAROCKS_VER=2.1.1
LIBYAML_VER=0.1.4
REDIS_VAR=2.6.16
BEANSTALKD_VER=1.9


cd ~
rm -fr $BUILD_DIR
mkdir -p $BUILD_DIR

mkdir -p $DEST_DIR
mkdir -p $THIRD_PARTY_DIR
mkdir -p $DEST_DIR/redis/bin
mkdir -p $DEST_DIR/beanstalkd/bin
mkdir -p $DEST_DIR/db
mkdir -p $DEST_DIR/logs
mkdir -p $DEST_DIR/conf
mkdir -p $DEST_DIR/openresty

# install openresty
cd $BUILD_DIR
wget http://openresty.org/download/ngx_openresty-$OPENRESTY_VER.tar.gz
tar zxf ngx_openresty-$OPENRESTY_VER.tar.gz
cd ngx_openresty-$OPENRESTY_VER

#don't need socket patch anymore
#rm -fr ngx_lua-*
#wget https://github.com/dualface/lua-nginx-module/archive/fix-sockets.zip
#unzip fix-sockets.zip
#rm fix-sockets.zip
#mv lua-nginx-module-fix-sockets ngx_lua-1
#cd ..

./configure --prefix=$DEST_DIR/openresty --with-luajit
make
make install

# compile lua codes to bytecode, and deploy them.
ln -f -s $DEST_DIR/openresty/luajit/bin/luajit-2.1.0-alpha /usr/bin/lua
ln -f -s $DEST_DIR/openresty/luajit/bin/luajit-2.1.0-alpha $DEST_DIR/openresty/luajit/bin/lua
cd $CUR_DIR/tool/
./compile_bytecode.sh

#deploy tool script
cp start.sh stop.sh status.sh reload.sh $DEST_DIR/openresty/nginx/. -f
cp start_quick_server.sh stop_quick_server.sh /opt/. -f 

#copy nginx conf file
cp $CUR_DIR/conf/nginx.conf $DEST_DIR/openresty/nginx/conf/. -f

# install luarocks
cd $BUILD_DIR
wget http://luarocks.org/releases/luarocks-$LUAROCKS_VER.tar.gz
tar zxf luarocks-$LUAROCKS_VER.tar.gz
cd luarocks-$LUAROCKS_VER

./configure --prefix=$DEST_DIR/openresty/luajit --with-lua=$DEST_DIR/openresty/luajit --with-lua-include=$DEST_DIR/openresty/luajit/include/luajit-2.1
make build
make install

# install lua extensions
LUAROCKS_BIN=$DEST_DIR/openresty/luajit/bin/luarocks

$LUAROCKS_BIN install luasocket
$LUAROCKS_BIN install lua-cjson
$LUAROCKS_BIN install luafilesystem

cd $BUILD_DIR
wget http://pyyaml.org/download/libyaml/yaml-$LIBYAML_VER.tar.gz
tar zxf yaml-$LIBYAML_VER.tar.gz
cd yaml-$LIBYAML_VER
./configure --prefix=$THIRD_PARTY_DIR
make
make install

$LUAROCKS_BIN install lyaml YAML_DIR=$THIRD_PARTY_DIR


# install redis
cd $BUILD_DIR
wget http://download.redis.io/releases/redis-$REDIS_VAR.tar.gz
tar zxf redis-$REDIS_VAR.tar.gz
cd redis-$REDIS_VAR
make
cp src/redis-server $DEST_DIR/redis/bin
cp src/redis-cli $DEST_DIR/redis/bin
cp src/redis-sentinel $DEST_DIR/redis/bin
cp src/redis-benchmark $DEST_DIR/redis/bin
cp src/redis-check-aof $DEST_DIR/redis/bin
cp src/redis-check-dump $DEST_DIR/redis/bin
cp redis.conf $DEST_DIR/conf

# install beanstalkd
cd $BUILD_DIR
wget https://github.com/kr/beanstalkd/archive/v$BEANSTALKD_VER.tar.gz -O beanstalkd-$BEANSTALKD_VER.tar.gz
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
