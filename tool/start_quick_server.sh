CURRDIR=$(pwd)
DIR=/opt/quick_server/openresty/nginx/
SRCDIR=/opt/quick-x-server/src/server/actions/tools/

cd $DIR
. ./start.sh

cd $SRCDIR
. ./cleaner.sh & > /opt/.cleaner.log

cd $CURRDIR

 



