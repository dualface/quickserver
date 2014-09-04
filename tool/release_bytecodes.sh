names=$(find ../src/ -name "*.lua")

for name in $names 
do
    #echo $name
    lua -b $name $name  
done
