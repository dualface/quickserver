CURRDIR=$(dirname $(readlink -f $0))
NGINX_DIR=$CURRDIR/openresty/nginx/

cd $NGINX_DIR
. ./sbin/reload.sh

cd $CURRDIR

