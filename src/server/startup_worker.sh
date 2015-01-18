#!/bin/bash
export LUA_PATH="/opt/qs/openresty/?.lua;/opt/qs/openresty/lualib/?.lua;;"

DIR=$(dirname $(readlink -f $0))
LUABIN=lua
SCRIPT=CmdBroadcastBootstrap.lua

cd $DIR

$LUABIN $DIR/$SCRIPT
