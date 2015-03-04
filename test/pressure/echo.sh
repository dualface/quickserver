#!/bin/bash

while [ 1 ]
do
    ab -n 10000 -c 200 http://localhost:8088/welcome_api?action=test.echo
done
