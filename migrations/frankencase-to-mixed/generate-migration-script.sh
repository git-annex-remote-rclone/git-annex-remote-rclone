#!/bin/bash

# Copyright (C) 2016 Daniel Dent

# This script will output a series of shell commands. I recommend redirectiong > output to a file.

if [ "$#" != "1" ]; then
  echo "usage: $0 targetgoeshere:prefixgoeshere"
  exit 1
fi  

REMOTE_PATH=$1

rclone ls $REMOTE_PATH | sed 's/^ *//' $TEMPFILE_1 | cut -f2 -d' ' | ./frankencase-to-mixed-helper.py $1
