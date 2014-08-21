if [ -d $1 ]; then 
    cd $1 
else
    exit -1
fi

#pwd > /tmp/1.txt 
git pull

shift
DEST=$1
shift
COMMIT=$1
git reset --hard $COMMIT 
cp ./* $DEST -rf
