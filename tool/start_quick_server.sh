CURRDIR=$(pwd)
DIR=/opt/quick_server/openresty/nginx/
SRCDIR=/opt/quick_server/openresty/server/actions/tools/

/opt/quick_server/redis/bin/redis-server /opt/quick_server/conf/redis.conf

service mysql start

cd $DIR
. ./start.sh

cd $SRCDIR
. ./cleaner.sh  > /dev/null 2> /opt/.cleaner.log &

cd $CURRDIR

 



