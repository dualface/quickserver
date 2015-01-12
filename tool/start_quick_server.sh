CURRDIR=$(dirname $(readlink -f $0))
NGINXDIR=$CURRDIR/openresty/nginx/
SRCDIR=$CURRDIR/openresty/packages/objectstorage/tools/

$CURRDIR/redis/bin/redis-server $CURRDIR/conf/redis.conf

service mysql start

cd $NGINXDIR
. ./sbin/start.sh

cd $SRCDIR
. ./cleaner.sh  > /dev/null 2> $NGINXDIR/log/cleaner.log &

cd $CURRDIR
