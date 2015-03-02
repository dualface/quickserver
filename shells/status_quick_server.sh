#!/bin/bash

echo -e "\n\033[41;37m [Nginx] \033[0m"
ps -ef | grep "nginx" | grep -v "grep" --color=auto

echo -e "\n\033[41;37m [Redis] \033[0m"
ps -ef | grep "redis" | grep -v "grep" --color=auto

echo -e "\n\033[41;37m [Beanstalkd] \033[0m"
ps -ef | grep "beanstalkd" | grep -v "grep" --color=auto

echo -e "\n\033[41;37m [Monitor] \033[0m"
ps -ef | grep "monitor.watch" | grep -v "grep" --color=auto

echo ""
