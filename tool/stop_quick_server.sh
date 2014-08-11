CURRDIR=$(pwd)
DIR=/opt/quick_server/openresty/nginx/
SRCDIR=/opt/quick-x-server/src/server/actions/tools/

PID=$(ps -ef | grep "sleep 60" | awk '{print $3}')

cd $DIR
./stop.sh

cd $CURRDIR

echo $PID 
kill -9 $PID

PID=$(ps -ef | grep "sleep 60" | awk '{print $2}')
kill -9 $PID



