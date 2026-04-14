#!/bin/bash
FULL_PATH="$(cd "$(dirname "$1")" && pwd)"
temp="${FULL_PATH##*/apps/}"

TYPE="${temp%%/*}"
APPNAME="${temp##*/}"

echo "TYPE: $TYPE APPNAME: $APPNAME"