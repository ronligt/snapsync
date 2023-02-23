#!/bin/bash

cd /snapsync/noquota; /snapsync/snapsync/cleanup.sh
cd /snapsync/withquota; /snapsync/snapsync/cleanup.sh