#precondition: 
# "lua" is the soft symbol link to luajit
# "jit.*" modules from luajit(usual in /opt/quick_server/openresty/luajit/share/...) is in LUA_PATH or current dir.

luajit=luajit-2.0.2
sudo cp /opt/quick_server/openresty/luajit/share/$luajit/jit . -rf

names=$(find ../src/ -name "*.lua")

for name in $names 
do
    #echo $name
    lua -b $name $name  
done

sudo rm ./jit -rf

cp -rf ../src/* /opt/quick_server/openresty/. 

git reset --hard HEAD
