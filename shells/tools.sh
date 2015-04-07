#!/bin/bash
export LUA_PATH="_QUICK_SERVER_ROOT_/src/?.lua;_QUICK_SERVER_ROOT_/src/lib/?.lua;;"

DIR=$(cd "$(dirname $0)" && pwd)
LUABIN=bin/openresty/luajit/bin/lua
SCRIPT=CLIBootstrap.lua

cd $DIR

ENV="SERVER_CONFIG=loadfile([[_QUICK_SERVER_ROOT_/conf/config.lua]])();DEBUG=_DBG_DEBUG;require([[framework.init]]);SERVER_CONFIG.appRootPath=SERVER_CONFIG.appRootPath..[[/tools]];"

$LUABIN -e "$ENV" $DIR/src/$SCRIPT $*
