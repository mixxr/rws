#!/bin/bash
source ../../vars_init.sh
TYPE="quotes"
STATUS=2
CMD_NAME="format2"
APPNAME=$(basename $(dirname $(pwd)))
echo "Format2 - APP NAME: $APPNAME, STATUS: $STATUS, CMD_NAME: $CMD_NAME"
gcloud beta run jobs deploy $TYPE-$APPNAME-job --source=. --region=europe-west1 --max-retries=0 \
--set-env-vars APPVERSION=$APPVERSION \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data