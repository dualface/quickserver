#!/bin/bash

if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

set -e

DEST_DIR=/opt/quick_server
BUILD_DIR=/tmp/install_quick_server
THIRD_PARTY_DIR=$DEST_DIR/third_party

OPENRESTY_VER=1.4.3.1
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

# install openresty
cd $BUILD_DIR
wget http://openresty.org/download/ngx_openresty-$OPENRESTY_VER.tar.gz
tar zxf ngx_openresty-$OPENRESTY_VER.tar.gz
cd ngx_openresty-$OPENRESTY_VER/bundle
rm -fr ngx_lua-*
wget https://github.com/dualface/lua-nginx-module/archive/fix-sockets.zip
unzip fix-sockets.zip
rm fix-sockets.zip
mv lua-nginx-module-fix-sockets ngx_lua-1
cd ..

./configure --prefix=$DEST_DIR/openresty --with-luajit \
    --with-cc-opt="-I/usr/local/Cellar/pcre/8.34/include" \
    --with-ld-opt="-L/usr/local/Cellar/pcre/8.34/lib"
make
make install

ln -s $DEST_DIR/openresty/luajit/bin/luajit $DEST_DIR/openresty/luajit/bin/lua

# install luarocks
cd $BUILD_DIR
wget http://luarocks.org/releases/luarocks-$LUAROCKS_VER.tar.gz
tar zxf luarocks-$LUAROCKS_VER.tar.gz
cd luarocks-$LUAROCKS_VER

./configure --prefix=$DEST_DIR/openresty/luajit --with-lua=$DEST_DIR/openresty/luajit --with-lua-include=$DEST_DIR/openresty/luajit/include/luajit-2.0
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
