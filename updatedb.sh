#!/bin/bash

DIR=`find $PREFIX -type d -maxdepth 1 -mindepth 1| sort`

for D in $DIR
do
  if [ ! -f $D/mlocate.db ]; then # we don't want to upgrade, yet...
    echo -n "Creating $D/mlocate.db... "
    /usr/local/bin/updatedb -U $D -o $D/mlocate.db
    echo "done"
  else
    echo $D "no go"
  fi
done
