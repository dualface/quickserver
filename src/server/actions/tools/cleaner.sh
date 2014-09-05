export LUA_PATH="/opt/quick_server/openresty/?.lua;/opt/quick_server/openresty/lualib/?.lua;;"

DIR=$(pwd)

INTER=60

while [ "1" = "1" ]
do 
    lua $DIR/cleaner.lua

    sleep $INTER 
done

