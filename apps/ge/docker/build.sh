#!/bin/bash
source ../../vars_init.sh  $(pwd) $1
echo "APPNAME: $APPNAME and TYPE: $TYPE"
gcloud beta run jobs deploy $TYPE-$APPNAME-job --source=. --region=europe-west1 \
--set-env-vars APPNAME=$APPNAME,APP_TYPE=$TYPE \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data 