export LUA_PATH="/opt/qs/openresty/?.lua;/opt/qs/openresty/lualib/?.lua;;"

DIR=$(pwd)

INTER=60

while [ "1" = "1" ]
do
    lua $DIR/cleaner.lua

    sleep $INTER
done

