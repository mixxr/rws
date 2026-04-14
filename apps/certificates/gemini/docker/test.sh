#!/bin/bash

echo pwd: $(pwd)
source ../../../build_init.sh  $(pwd)
echo $TYPE
echo $APPNAME
# test if TYPE and APPNAME are correctly set
if [ -z "$TYPE" ] || [ -z "$APPNAME" ]; then
  echo "Error: TYPE or APPNAME is not set."
  exit 1
fi
