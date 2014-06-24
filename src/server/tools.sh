#!/bin/bash

. ~/.profile

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LUABIN=lua
SCRIPT=tools.lua
SCRIPTS_ROOT_DIR=$(dirname $DIR)

cd $DIR

$LUABIN -e "package.path='$SCRIPTS_ROOT_DIR/?.lua;;'" $SCRIPT $*
