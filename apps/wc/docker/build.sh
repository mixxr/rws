#!/bin/bash
# test if $1 and $2 are set
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: $0 <type[tickers|details|quotes]> <status_from[1|2|3]> <cmd_name>[webclaw|curl]"
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
# source ../../check_input.sh  $1 $2 $3
TYPE=$1
STATUS=$2
CMD_NAME=$3
APPNAME=$(basename $(dirname $(pwd)))

echo "APP NAME: $APPNAME, STATUS: $STATUS, TYPE: $TYPE, CMD_NAME: $CMD_NAME"
echo "====> Remember to create jobs with creates_jobs.sh script before executing this job."
gcloud beta run jobs deploy $TYPE-$APPNAME-S$STATUS-job --source=. --region=europe-west1 --max-retries=1 \
--set-env-vars STATUS=$STATUS,APP_TYPE=$TYPE,CMD_NAME=$CMD_NAME \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data