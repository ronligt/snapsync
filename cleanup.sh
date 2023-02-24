#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTDIR=$(dirname $0)

# Default settings for retention scheme
DOW="Friday"  # which weekday must be kept
MAXWEEK=52    # how many weekdays must be kept
MAXDAY=31     # how many days must be kept
MAXHOUR=1     # how many hours must be kept: MAXHOUR*24 hours

# Get env var if given
DOW="${SNAPSYNC_DOW:-$DOW}"
MAXWEEK="${SNAPSYNC_MAXWEEK:-$MAXWEEK}"
MAXDAY="${SNAPSYNC_MAXDAY:-$MAXDAY}"
MAXHOUR="${SNAPSYNC_MAXHOUR:-$MAXHOUR}"

# Ya gotta have limits!
WEEKDAYS="Monday Tuesday Wednesday Thursday Friday Saturday Sunday"
MAX_MAXWEEK=52 # one year
MAX_MAXDAY=365 # one year
MAX_MAXHOUR=168 # one week

# Check if var is in list
function exists_in_list() {
    LIST=$1
    DELIMITER=$2
    VALUE=$3
    [[ "$LIST" =~ ($DELIMITER|^)$VALUE($DELIMITER|$) ]]
}
if ! exists_in_list "$WEEKDAYS" " " $DOW ; then
  echo "Error: DOW is not in list [$WEEKDAYS]" >&2; exit 1
fi
# Check if var is number
re='^[0-9]+$'
if ! [[ $MAXWEEK =~ $re ]] ; then
  echo "Error: MAXWEEK is not a number" >&2; exit 1
else
  if ! [ "$MAXWEEK" -ge 0 ] && [ "$MAXWEEK" -le "$MAX_MAXWEEK" ] ; then
    echo "Error: MAXWEEK is not in range [0-$MAX_MAXWEEK]" >&2; exit 1
  fi
fi
if ! [[ $MAXDAY =~ $re ]] ; then
  echo "Error: MAXDAY is not a number" >&2; exit 1
else
  if ! [ "$MAXDAY" -ge 0 ] && [ "$MAXDAY" -le "$MAX_MAXDAY" ] ; then
    echo "Error: MAXWEEK is not in range [0-$MAX_MAXDAY]" >&2; exit 1
  fi
fi
if ! [[ $MAXHOUR =~ $re ]] ; then
  echo "Error: MAXHOUR is not a number" >&2; exit 1
else
  if ! [ "$MAXHOUR" -ge 0 ] && [ "$MAXHOUR" -le "$MAX_MAXHOUR" ] ; then
    echo "Error: MAXHOUR is not in range [0-$MAX_MAXHOUR]" >&2; exit 1
  fi
fi

function usage {
    echo "$SCRIPTNAME"
    echo ""
    echo "usage: $SCRIPTNAME <SNAPSYNC DIR>"
    echo "  <SNAPSYNC DIR>    location where all backups are stored"
    echo ""
    echo "description: Cleanup snapsync backups according to retention scheme"
    echo ""
    echo "With every call of $SCRIPTNAME the snapsync directory is cleaned up"
    echo "according to the retention scheme. Only the following snapshots are kept:"
    echo "1. the oldest one"
    echo "2. the first backup in a month"
    echo "3. Every $DOW [SNAPSYNC_DOW] of the last $MAXWEEK [SNAPSYNC_MAXWEEK] weeks"
    echo "4. Every first backup of the last $MAXDAY [SNAPSYNC_MAXDAY] days"
    echo "5. Every backup in the last $(echo $MAXHOUR*24 | bc) [SNAPSYNC_MAXHOUR] hours"
    echo "note: the retention scheme can be easily modified using the environment"
    echo "variables shown in square brackets."
}

if [ $# != 1 ];
then
  usage
  exit 1
fi

PREFIX=$1
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

echo "Starting $SCRIPTNAME"
date

if [ -e $LCK ]; then
  DATE=`date -r $LCK`
  SCRIPT=`cat $LCK`
  echo "Error: lockfile $LCK exists! Most likely the $SCRIPT script is allready running." >&2
  echo "       This lockfile is created on: $DATE" >&2
  exit 1
else
  echo $SCRIPTNAME > $LCK
fi

# first backup ever
first=`ls -td 2* | tail -1`

# MONTHS, keep every first backup of the month (NOTE: including the oldest!)
i=0
cont=1
findstr=""
while [ "$cont" = "1" ]; do
  datestr=`date --date "now -$i month" +"%Y%m"`
  if [ "$datestr" -ge "${first:0:6}" ]; then
    month=`find . -maxdepth 1 -mindepth 1 -name "$datestr*" -type d -printf "%f\n"| sort | head -1`
    if [ "$month" != "" ]; then
      findstr=$(echo $findstr " ! -name $month")
    fi
    i=$(echo "$i + 1" | bc)
  else
    cont=0
  fi
done

# WEEKS, keep last $MAXWEEK weekdays ($DOW)
nowstr=`date +"%Y%m%d"`
i=0
cont=1
noweeks=0
while [ "$cont" = "1" ]; do
  datestr=`date --date "now -$i week $DOW" +"%Y%m%d"`
  if [ "$datestr" -ge "${first:0:8}" ]; then
    if [ "$datestr" -le "$nowstr" ]; then
      week=`find . -maxdepth 1 -mindepth 1 -name "$datestr*" -type d -printf "%f\n" | sort | head -1`
      noweeks=$(echo "$noweeks + 1" | bc)
      if [ "$noweeks" = "$MAXWEEK" ]; then
        cont=0
      fi
      if [ "$week" != "" ]; then
        findstr=$(echo $findstr " ! -name $week")
      fi
    fi
    i=$(echo "$i + 1" | bc)
  else
    cont=0
  fi
done

# DAYS, keep last $MAXDAY days
nowstr=`date +"%Y%m%d"`
i=0
cont=1
nodays=0
while [ "$cont" = "1" ]; do
  datestr=`date --date "now -$i day" +"%Y%m%d"`
  if [ "$datestr" -ge "${first:0:8}" ]; then
    if [ "$datestr" -le "$nowstr" ]; then
      day=`find . -maxdepth 1 -mindepth 1 -name "$datestr*" -type d -printf "%f\n" | sort | head -1`
      nodays=$(echo "$nodays + 1" | bc)
      if [ "$nodays" = "$MAXDAY" ]; then
        cont=0
      fi
      if [ "$day" != "" ]; then
        findstr=$(echo $findstr " ! -name $day")
      fi
    fi
    i=$(echo "$i + 1" | bc)
  else
    cont=0
  fi
done

# HOURS, keep last $MAXHOUR*24 hours
findstr=$(echo $findstr " ! -mtime -$MAXHOUR")

#find . -maxdepth 1 -mindepth 1 -type d $findstr -printf "%f\n" -exec rm -rf {} \;
echo $findstr
find . -maxdepth 1 -mindepth 1 -type d $findstr -printf "%f\n"

echo_lap $START "total script"

echo "============================"

rm -f $LCK