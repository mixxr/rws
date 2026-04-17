#!/bin/bash
APPNAME=$(basename $(dirname $1))
TYPE=$2
# test if TYPE is correctly set
if [ -z "$TYPE" ]; then
  echo "Please provide TYPE (details, tickers, quotes) as argument. Usage: ./build.sh <TYPE>"
  exit 1
fi
case "$TYPE" in
  details|tickers|quotes)
    ;;
  *)
    echo "Error: TYPE must be one of: details, tickers, quotes. Got: $TYPE"
    exit 1
    ;;
esac

echo "TYPE: $TYPE APPNAME: $APPNAME"