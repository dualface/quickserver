#!/bin/bash

echo -e "\n\033[41;37m [Nginx] \033[0m"
ps -ef | grep "nginx"  --color=auto

echo -e "\n\033[41;37m [Redis] \033[0m"
ps -ef | grep "redis" --color=auto

echo -e "\n\033[41;37m [Beanstalkd] \033[0m"
ps -ef | grep "beanstalkd" --color=auto
