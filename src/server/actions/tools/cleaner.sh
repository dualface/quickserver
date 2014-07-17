export LUA_PATH="/home/cheeray/work/quick-x-server/src/?.lua;/opt/quick_server/openresty/lualib/?.lua;;"

DIR=$(pwd)

while [ "1" = "1" ]
do 
    lua $DIR/cleaner.lua

    sleep 10
done

