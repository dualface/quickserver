#!/bin/bash

echo -e "\n\033[33m[Nginx] \033[0m"
ps -ef | grep "nginx" | grep -v "grep" --color=auto

echo -e "\n\033[33m[Redis] \033[0m"
ps -ef | grep "redis" | grep -v "grep" --color=auto

echo -e "\n\033[33m[Beanstalkd] \033[0m"
ps -ef | grep "beanstalkd" | grep -v "grep" --color=auto

echo -e "\n\033[33m[Monitor] \033[0m"
ps -ef | grep "monitor.watch" | grep -v "grep" --color=auto | grep -v "lua -e SERVER_CONFIG" --color=auto

echo ""
