#!/bin/bash

paths=$(locate --database /data/snapsync/home/mlocate.db $1 | sort)

for path in $paths
do
    snapdate=$(cut -f5 -d'/')
    echo $snapdate
done