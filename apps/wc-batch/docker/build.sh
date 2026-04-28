#!/bin/bash
TYPE="quotes"
STATUS=1
CMD_NAME="webclaw"
APPNAME=$(basename $(dirname $(pwd)))
echo "Webclaw batch mode - APP NAME: $APPNAME, STATUS: $STATUS, CMD_NAME: $CMD_NAME"
gcloud beta run jobs deploy $TYPE-$APPNAME-job --source=. --region=europe-west1 \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data \
--execute-now