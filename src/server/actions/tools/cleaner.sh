export LUA_PATH="/home/cheeray/work/quick-x-server/src/?.lua;/opt/quick_server/openresty/lualib/?.lua;;"

DIR=$(pwd)

lua $DIR/cleaner.lua
