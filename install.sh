#!/bin/bash

function showHelp()
{
    echo "Usage: [sudo] ./install.sh [--prefix=absolute_path] [OPTIONS]"
    echo "Options:"
    echo -e "\t -a | --all \t\t install nginx(openresty) and Quick Server framework, redis and beanstalkd"
    echo -e "\t -n | --nginx \t\t install nginx(openresty) and Quick Server framework"
    echo -e "\t -r | --redis \t\t install redis"
    echo -e "\t -b | --beanstalkd \t install beanstalkd"
    echo -e "\t -h | --help \t\t show this help"
    echo "if the option is not specified, default option is \"--all(-a)\"."
    echo "if the \"--prefix\" is not specified, default path is \"/opt/quick_server\"."
}

function checkOSType()
{
    type "apt-get" > /dev/null 2> /dev/null
    if [ $? -eq 0 ]; then
        echo "UBUNTU"
        exit 0
    fi

    type "yum" > /dev/null 2> /dev/null
    if [ $? -eq 0 ]; then
        echo "CENTOS"
        exit 0
    fi

    RES=$(uname -s)
    if [ $RES == "Darwin" ]; then
        echo "MACOS"
        exit 0
    fi

    echo "UNKNOW"
    exit 1
}

if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

OSTYPE=$(checkOSType)
CUR_DIR=$(cd "$(dirname $0)" && pwd)
BUILD_DIR=/tmp/install_quick_server
DEST_DIR=/opt/quick_server

declare -i ALL=0
declare -i BEANS=0
declare -i NGINX=0
declare -i REDIS=0

OPENRESTY_VER=1.7.7.1
LUASOCKET_VER=3.0-rc1
REDIS_VAR=2.6.16
BEANSTALKD_VER=1.9

if [ $OSTYPE == "MACOS" ]; then
    gcc -o $CUR_DIR/shells/getopt_long $CUR_DIR/shells/src/getopt_long.c
    ARGS=$($CUR_DIR/shells/getopt_long "$@")
else
    ARGS=$(getopt -o abrnh --long all,nginx,redis,beanstalkd,help,prefix: -n 'Install quick server' -- "$@")
fi

if [ $? != 0 ] ; then
    echo "Install Quick Server Terminating..." >&2;
    exit 1;
fi

eval set -- "$ARGS"

if [ $# -eq 1 ] ; then
    ALL=1
fi

if [ $# -eq 3 ] && [ $1 == "--prefix" ] ; then
    ALL=1
fi

while true ; do
    case "$1" in
        --prefix)
            DEST_DIR=$2
            shift 2
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

        --)
            shift;
            break
            ;;

        *)
            echo "invalid option: $1"
            exit 1
            ;;
    esac
done

DEST_BIN_DIR=$DEST_DIR/bin

if [ $OSTYPE == "UBUNTU" ] ; then
    apt-get install -y build-essential libpcre3-dev libssl-dev git-core unzip
elif [ $OSTYPE == "CENTOS" ]; then
    yum groupinstall -y "Development Tools"
    yum install -y pcre-devel zlib-devel openssl-devel unzip
elif [ $OSTYPE == "MACOS" ]; then
    type "brew" > /dev/null 2> /dev/null
    TMP=$?
    type "gcc" > /dev/null 2> /dev/null
    if [ $? -ne 0 ] || [ $TMP -ne 0 ]; then
        echo "Please install xcode and brew, then run \"brew install pcre\"."
        exit 0
    fi
else
    echo "Unsupport current OS."
    exit 1
fi

if [ $OSTYPE == "MACOS" ]; then
    SED_BIN='sed -i --'
else
    SED_BIN='sed -i'
fi

set -e

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cp -f $CUR_DIR/installation/*.tar.gz $BUILD_DIR

mkdir -p $DEST_DIR
mkdir -p $DEST_BIN_DIR

mkdir -p $DEST_DIR/logs
mkdir -p $DEST_DIR/tmp
mkdir -p $DEST_DIR/conf
mkdir -p $DEST_DIR/db

# install nginx and Quick Server framework
if [ $ALL -eq 1 ] || [ $NGINX -eq 1 ] ; then
    cd $BUILD_DIR
    tar zxf ngx_openresty-$OPENRESTY_VER.tar.gz
    cd ngx_openresty-$OPENRESTY_VER
    mkdir -p $DEST_BIN_DIR/openresty

    # install openresty
    ./configure --prefix=$DEST_BIN_DIR/openresty --with-luajit --with-http_stub_status_module
    make
    make install

    # install quick server framework
    ln -f -s $DEST_BIN_DIR/openresty/luajit/bin/luajit-2.1.0-alpha $DEST_BIN_DIR/openresty/luajit/bin/lua
    cp -rf $CUR_DIR/src $DEST_DIR
    cp -rf $CUR_DIR/apps $DEST_DIR
    cp -rf $CUR_DIR/tools $DEST_DIR

    # deploy tool script
    cd $CUR_DIR/shells/
    cp -f start_quick_server.sh stop_quick_server.sh status_quick_server.sh tools.sh $DEST_DIR
    ln -f -s $DEST_BIN_DIR/openresty/nginx/sbin/nginx /usr/bin/nginx
    # if it in Mac OS X, getopt_long should be deployed.
    if [ $OSTYPE == "MACOS" ]; then
        cp -f $CUR_DIR/shells/getopt_long $DEST_DIR/tmp
    fi

    # copy nginx and Quick Server framework conf file
    cp -f $CUR_DIR/conf/nginx.conf $DEST_BIN_DIR/openresty/nginx/conf/.
    $SED_BIN "s#_QUICK_SERVER_ROOT_#$DEST_DIR#g" $DEST_BIN_DIR/openresty/nginx/conf/nginx.conf
    rm -f $DEST_BIN_DIR/openresty/nginx/conf/nginx.conf--

    cp -f $CUR_DIR/conf/config.lua $DEST_DIR/conf
    $SED_BIN "s#_QUICK_SERVER_ROOT_#$DEST_DIR#g" $DEST_DIR/conf/config.lua
    rm -f $DEST_DIR/conf/config.lua--

    # modify tools path
    $SED_BIN "s#_QUICK_SERVER_ROOT_#$DEST_DIR#g" $DEST_DIR/tools.sh
    $SED_BIN "s#_QUICK_SERVER_ROOT_#$DEST_DIR#g" $DEST_DIR/tools/actions/MonitorAction.lua
    rm -f $DEST_DIR/tools.sh--
    rm -f $DEST_DIR/tools/actions/MonitorAction.lua--


    # install luasocket
    cd $BUILD_DIR
    tar zxf luasocket-$LUASOCKET_VER.tar.gz
    cd luasocket-$LUASOCKET_VER
    if [ $OSTYPE == "MACOS" ]; then
        $SED_BIN "s#PLAT?= linux#PLAT?= macosx#g" makefile
        $SED_BIN "s#PLAT?=linux#PLAT?=macosx#g" src/makefile
        $SED_BIN "s#LUAPREFIX_macosx?=/opt/local#LUAPREFIX_macosx?=$DEST_BIN_DIR/openresty/luajit#g" src/makefile
        $SED_BIN "s#LUAINC_macosx_base?=/opt/local/include#LUAINC_macosx_base?=$DEST_BIN_DIR/openresty/luajit/include#g" src/makefile
        $SED_BIN "s#\$(LUAINC_macosx_base)/lua/\$(LUAV)#\$(LUAINC_macosx_base)/luajit-2.1#g" src/makefile
    else
        $SED_BIN "s#LUAPREFIX_linux?=/usr/local#LUAPREFIX_linux?=$DEST_BIN_DIR/openresty/luajit#g" src/makefile
        $SED_BIN "s#LUAINC_linux_base?=/usr/include#LUAINC_linux_base?=$DEST_BIN_DIR/openresty/luajit/include#g" src/makefile
        $SED_BIN "s#\$(LUAINC_linux_base)/lua/\$(LUAV)#\$(LUAINC_linux_base)/luajit-2.1#g" src/makefile
    fi
    make && make install
    cp -f src/serial.so src/unix.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1/socket/.

    # install cjson
    cp -f $DEST_BIN_DIR/openresty/lualib/cjson.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1/.

    # install http client
    cd $BUILD_DIR
    tar zxf luahttpclient.tar.gz
    cp -f httpclient.lua $DEST_BIN_DIR/openresty/luajit/share/lua/5.1/.
    cp -rf httpclient $DEST_BIN_DIR/openresty/luajit/share/lua/5.1/.

    # install inspect
    cd $BUILD_DIR
    tar zxf luainspect.tar.gz
    cp -f inspect.lua $DEST_BIN_DIR/openresty/luajit/share/lua/5.1/.

    # install docs
    cp -rf $CUR_DIR/docs/build/html $DEST_DIR/docs

    echo "Install Openresty and Quick Server framework DONE"
fi

#install redis
if [ $ALL -eq 1 ] || [ $REDIS -eq 1 ] ; then
    cd $BUILD_DIR
    tar zxf redis-$REDIS_VAR.tar.gz
    cd redis-$REDIS_VAR
    mkdir -p $DEST_BIN_DIR/redis/bin

    make
    cp src/redis-server $DEST_BIN_DIR/redis/bin
    cp src/redis-cli $DEST_BIN_DIR/redis/bin
    cp src/redis-sentinel $DEST_BIN_DIR/redis/bin
    cp src/redis-benchmark $DEST_BIN_DIR/redis/bin
    cp src/redis-check-aof $DEST_BIN_DIR/redis/bin
    cp src/redis-check-dump $DEST_BIN_DIR/redis/bin

    mkdir -p $DEST_BIN_DIR/redis/conf
    cp -f $CUR_DIR/conf/redis.conf $DEST_BIN_DIR/redis/conf/.
    $SED_BIN "s#_QUICK_SERVER_ROOT_#$DEST_DIR#g" $DEST_BIN_DIR/redis/conf/redis.conf
    rm -f $DEST_BIN_DIR/redis/conf/redis.conf--

    echo "Install Redis DONE"
fi

# install beanstalkd
if [ $ALL -eq 1 ] || [ $BEANS -eq 1 ] ; then
    cd $BUILD_DIR
    tar zxf beanstalkd-$BEANSTALKD_VER.tar.gz
    cd beanstalkd-$BEANSTALKD_VER
    mkdir -p $DEST_BIN_DIR/beanstalkd/bin

    make
    cp beanstalkd $DEST_BIN_DIR/beanstalkd/bin

    echo "Install Beanstalkd DONE"
fi

# done

echo ""
echo ""
echo ""
echo "DONE!"
echo ""
echo ""
