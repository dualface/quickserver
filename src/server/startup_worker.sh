#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LUABIN=lua
SCRIPT=worker_bootstrap.lua
SCRIPTS_ROOT_DIR=$(dirname $DIR)
FRAMEWORK_ROOT_DIR=/mnt/framework

cd $DIR

echo $LUABIN -e "package.path='$SCRIPTS_ROOT_DIR/?.lua;$FRAMEWORK_ROOT_DIR/?.lua;;'" $SCRIPT
$LUABIN -e "package.path='$SCRIPTS_ROOT_DIR/?.lua;$FRAMEWORK_ROOT_DIR/?.lua;;'" $SCRIPT
