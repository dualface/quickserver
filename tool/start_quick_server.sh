CURRDIR=$(dirname $(readlink -f $0))
NGINX_DIR=$CURRDIR/openresty/nginx/
SRCDIR=$CURDIR/openresty/server/actions/tools/

$CURDIR/redis/bin/redis-server $CURDIR/conf/redis.conf

service mysql start

cd $NGINX_DIR
. ./sbin/start.sh

cd $SRCDIR
. ./cleaner.sh  > /dev/null 2> /opt/.cleaner.log &

cd $CURRDIR

 



