#!/bin/bash
# test if $1 and $2 are set
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <type[tickers|details|quotes]> <status_from[1|2|3]>"
  exit 1
fi
TYPE=$1
STATUS=$2
CMD_NAME="geminicert"
APPNAME=$(basename $(dirname $(pwd)))

case "$TYPE" in
  details|tickers|quotes)
    ;;
  *)
    echo "Error: TYPE must be one of: details, tickers, quotes. Got: $TYPE"
    exit 1
    ;;
esac
# source ../../check_input.sh  $1 $2 $3

echo "APP NAME: $APPNAME, STATUS: $STATUS, TYPE: $TYPE, CMD_NAME: $CMD_NAME"
echo "====> Remember to create jobs with creates_jobs.sh script before executing this job."
gcloud beta run jobs deploy $TYPE-$APPNAME-s$STATUS-job --source=. --region=europe-west1 \
--set-env-vars STATUS=$STATUS,APP_TYPE=$TYPE,CMD_NAME=$CMD_NAME \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data