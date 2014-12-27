CURRDIR=$(dirname $(readlink -f $0))
NGINX_DIR=$CURRDIR/openresty/nginx/
SRCDIR=$CURRDIR/openresty/server/actions/tools/

$CURRDIR/redis/bin/redis-server $CURRDIR/conf/redis.conf

service mysql start

cd $NGINX_DIR
. ./sbin/start.sh

cd $SRCDIR
. ./cleaner.sh  > /dev/null 2> /opt/.cleaner.log &

cd $CURRDIR

 



