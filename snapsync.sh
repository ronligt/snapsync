#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTDIR=$(dirname $0)

function usage {
    echo "$SCRIPTNAME"
    echo ""
    echo "usage: $SCRIPTNAME <SOURCE DIR> <SNAPSYNC DIR>"
    echo "  <SOURCE DIR>      all files and directories in this directory are backuped"
    echo "  <SNAPSYNC DIR>    location where all backups are stored"
    echo ""
    echo "description: Backup solution with snapshots using hard links"
    echo ""
    echo "With every call of $SCRIPTNAME a copy of the previous snapshot is created"
    echo "using hard links after which all modifications are synchronised via rsync."
    echo "Each snapshot is stored with its creation date. A softlink named 'last'"
    echo "points to the latest snapshot"
}

if [ $# != 2 ];
then
  usage
  exit 1
fi

SRC=$1
PREFIX=$2
LNK=$PREFIX/last
LCK=$PREFIX/lock
MDB=$PREFIX/mlocate.db

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

START=`date +%s`
echo "Starting $SCRIPTNAME"
date

if [ -e $LCK ]; then
  DATE=`date -r $LCK`
  SCRIPT=`cat $LCK`
  echo "Error: lockfile $LCK exists! Most likely the $SCRIPT script is already running." >&2
  echo "       This lockfile is created on: $DATE" >&2
  exit 1
else
  echo $SCRIPTNAME > $LCK
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

rsync -ax --stats -h --delete $SRC/ $DST 2> $PREFIX/error.log
echo_lap $LAP "rsyncing"

touch $DST

unlink $LNK
ln -s $DST $LNK

updatedb -U $PREFIX -o $MDB
echo_lap $LAP "updating mlocate.db"

echo_lap $START "total script"

echo "============================"

rm -f $LCK
