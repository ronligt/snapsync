#!/bin/bash

function check_locver {
if [ -f $1 ]; then
  LOCVER=`$1 --version`
  if [ -n "$(echo $LOCVER | sed -n 's/\(Secure\)/\1/p')" ]; then
    LOCTYPE="slocate"
  elif [ -n "$(echo $LOCVER | sed -n 's/\(mlocate\)/\1/p')" ]; then
    LOCTYPE="mlocate"
  else
    LOCTYPE="gnulocate"
  fi
else
  LOCTYPE="none"
fi
}

LOCBIN="/usr/bin/locate"
check_locver $LOCBIN
if [[ ( "$LOCTYPE" = "slocate" ) || ( "$LOCTYPE" = "none" ) ]]; then
  LOCBIN="/usr/local/bin/locate"
  check_locver $LOCBIN
  if [[ ( "$LOCTYPE" = "slocate" ) || ( "$LOCTYPE" = "none" ) ]]; then
    echo "Error: no usable 'locate' availabe (must GNU locate or mlocate)"
    exit 1;
  fi
fi

# find all databases
DBS=`find /rsync -name "mlocate.db" -maxdepth 2 -mindepth 2 -printf %p:`
# this is fun: ${DBS%?} removes last character from $DBS, thereby removing the empty ":" created by the find above
# also note: the "\\$1" is needed to escape the \, otherwise the $ is escaped and 'locate' will only look for $1 :-p
$LOCBIN --database=${DBS%?} -b "\\$1" | xargs stat --format="%Z %n %i" | sort -n | uniq -f 2 | cut -f 2 -d" " | xargs ls -l
