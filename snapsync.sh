#!/bin/bash

START=`date +%s`

SCRIPTDIR=$(dirname $0)
SRC=$1
PREFIX=$2
LNK=$PREFIX/last
LCK=$PREFIX/lock

# determine laptime and echo result
#   $1 = start time for lap
#   $2 = activity for echo result
function echo_lap() {
  LOCLAP=`date +%s`
  SEC=`echo $LOCLAP-$1 | bc`
  TIME=`date -d "1970-1-1 +$SEC seconds" +%T`
  echo "Done $2 in $TIME"
  LAP=$LOCLAP
}

date

if [ -e $LCK ]; then
  DATE=`date -r $LCK`
  echo "Error: lockfile $LCK exists! Most likely this script is allready running."
  echo "       This lockfile is created on: $DATE"
  exit 1
else
  touch $LCK
fi

DST=$PREFIX/`date +%Y%m%d%H%M%S`

if [ -e $LNK ]; then
  if [ -h $LNK ]; then
    PREV=`readlink -f $LNK`
    cp -al $PREV $DST
    echo_lap $START "copying $PREV to $DST"
  else
    echo "Error: $LNK exists but is not a symbolic link!"
    exit 1
  fi
fi

rsync -ax --stats --delete $SRC/ $DST 2> $PREFIX/error.log | $SCRIPTDIR/parse_rsync.sh
echo_lap $LAP "rsyncing"

touch $DST

unlink $LNK
ln -s $DST $LNK

#/usr/local/bin/updatedb -U $DST -o $DST/mlocate.db
#echo_lap $LAP "updating mlocate.db"

echo_lap $START "total script"

echo "============================"

rm -f $LCK