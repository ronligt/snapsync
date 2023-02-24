#!/bin/bash

DOW="Friday"  # which weekday must be kept
MAXWEEK=52    # how many weekdays must be kept
MAXDAY=31     # how many days must be kept

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
findstr=$(echo $findstr " ! -mtime -$MAXDAY")

find . -maxdepth 1 -mindepth 1 -type d $findstr -printf "%f\n" -exec rm -rf {} \;
#find . -maxdepth 1 -mindepth 1 -type d $findstr -printf "%f\n"
