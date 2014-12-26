#precondition: 
# "lua" is the soft symbol link to luajit
# "jit.*" modules from luajit(usual in /opt/quick_server/openresty/luajit/share/...) is in LUA_PATH or current dir.

if [ $# -ne 1 ]; then exit 1 ; fi

luajit=luajit-2.1.0-alpha
DEST_DIR=$1
sudo cp $DEST_DIR/openresty/luajit/share/$luajit/jit . -rf

names=$(find ../src/ -name "*.lua")

for name in $names 
do
    #echo $name
    lua -b $name $name  
done

sudo rm ./jit -rf

cp -rf ../src/* $DEST_DIR/openresty/. 

git reset --hard HEAD

#config.lua don't need compiling.
cp -f ../src/server/config.lua $DEST_DIR/openresty/server/.
