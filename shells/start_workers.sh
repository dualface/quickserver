#!/bin/bash
export LUA_PATH="_QUICK_SERVER_ROOT_/src/?.lua;_QUICK_SERVER_ROOT_/src/lib/?.lua;;"

DIR=$(dirname $(readlink -f $0))
LUABIN=bin/openresty/luajit/bin/lua
SCRIPT=WorkerBootstrap.lua

cd $DIR

ENV="SERVER_CONFIG=loadfile([[_QUICK_SERVER_ROOT_/conf/config.lua]])(); DEBUG=_DBG_DEBUG; require([[framework.init]]); SERVER_CONFIG.appRootPath=SERVER_CONFIG.quickserverRootPath .. [[bin/instrument/workers/?.lua]] .. SERVER_CONFIG.appRootPath .. [[/workers]];"


echo "$1" | grep -i "monitor.watch" > /dev/null
if [ $? -eq 0 ]; then
    $LUABIN -e "$ENV" $DIR/src/$SCRIPT $*
    exit 0
fi

NUMOFWORKERS=$($LUABIN -e "$ENV" -e "print(SERVER_CONFIG.numOfWorkers)")

declare -i I=0
while [ $I -le $NUMOFWORKERS ]; do
    $LUABIN -e "$ENV" $DIR/src/$SCRIPT $*
    let I=I+1
done

while true; do
    NUM=$(ps -ef | grep -i "lua.*jobworker.handler" | grep -v "grep" | wc -l)
    if [ $NUM -le $NUMOFWORKERS ]; then
        $LUABIN -e "$ENV" $DIR/src/$SCRIPT $*
    fi
    sleep 1
done
