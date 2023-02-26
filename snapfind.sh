#!/bin/bash

# paths=$(locate --database /data/snapsync/home/mlocate.db $1 | sort | sort -t'/' -k6)
paths=$(locate --database /data/snapsync/home/mlocate.db $1 | sort | xargs ls -im | sort)
echo $paths

IFS=','
prev_inode=""
for path in $paths
do
    path=$(echo $path|tr -d '\n')
    echo $path
    snapdate=$(echo -n $path|cut -f5 -d'/')
    echo $snapdate
    inode=$(echo -n $path|cut -f1 -d' ')
    echo $inode
    snappath=$(echo -n $path|cut -f6- -d'/')
    echo $snappath
    if [[ "$inode" != "$prev_inode" ]];
    then
        if [[ "$prev_inode" != "" ]];
        then
            echo "    identical from " $first_snapdate to $prev_snapdate
        fi
        echo $snappath "first occurence on" $snapdate
        first_snapdate=$snapdate
        prev_inode=$inode
    else
        prev_snapdate=$snapdate
    fi
done
unset IFS