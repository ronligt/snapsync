#!/bin/bash

in=$(cat)

echo "${in}" | grep 'files' | cut -f 2 -d ":" | xargs | awk '{print "Transferred files: " $2 "/" $1 " [" int($2/$1*100) "%]"}'
echo "${in}" | grep 'Total' | grep 'size' | cut -f 2 -d":" | cut -f 2 -d" " | xargs | awk '{ split( "B KB MB GB TB" , v ); a=$1;b=$2;s=1;t=1; while( a>1024 ){ a/=1024; s++ } while( b>1024){ b/=1024; t++} print "Transferred bytes: " int(b) v[t] "/" int(a) v[s] " [" int($2/$1*100) "%]" }'
