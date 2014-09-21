echo "[NGINX]"
ps -ef | grep "nginx"  --color=auto

echo -e "\n[Cleaner]"
ps -ef | grep "sleep" --color=auto

echo -e "\n[Redis]"
ps -ef | grep "redis" --color=auto

echo -e "\n[Mysql]"
ps -ef | grep "mysql" --color=auto
