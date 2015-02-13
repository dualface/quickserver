#!/bin/bash
export LUA_PATH="/opt/qs/src/?.lua;/opt/qs/src/lib/?.lua;;"

DIR=$(dirname $(readlink -f $0))
LUABIN=lua
SCRIPT=CLIBootstrap.lua

cd $DIR

ENV="SERVER_CONFIG = loadfile([[/opt/qs/conf/config.lua]])(); DEBUG = _DBG_DEBUG; require([[framework.init]]); SERVER_CONFIG.appRootPath = SERVER_CONFIG.quickserverRootPath .. [[/tools]]"

$LUABIN -e $ENV $DIR/src/$SCRIPT $*
