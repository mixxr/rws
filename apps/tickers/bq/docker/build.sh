#!/bin/bash
# TYPES is a comma separated string
TYPES="tickers,details"
STATUS=3
CMD_NAME="gs_load"
APPNAME=$(basename $(dirname $(pwd)))

echo "APP NAME: $APPNAME, STATUS: $STATUS, TYPES: $TYPES, CMD_NAME: $CMD_NAME"
gcloud beta run jobs deploy $APPNAME-s$STATUS-job --source=. --region=europe-west1 --max-retries=1 \
--set-env-vars STATUS=$STATUS,APP_TYPES=$TYPES,CMD_NAME=$CMD_NAME,TABLE_PREFIX=staging_ \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data