if [ -d $1 ]; then 
    cd $1 
else
    exit -1
fi

#pwd > /tmp/1.txt 
git pull >> /tmp/1.txt

shift
DEST=$1
shift
cp $* $DEST
