CURRDIR=$(dirname $(readlink -p $0))
NGINX_DIR=$CURRDIR/openresty/nginx/

PID=$(ps -ef | grep "sleep 60" | awk '{print $3}')

cd $NGINX_DIR
./stop.sh

cd $CURRDIR

echo $PID 
kill -9 $PID

PID=$(ps -ef | grep "sleep 60" | awk '{print $2}')
kill -9 $PID

