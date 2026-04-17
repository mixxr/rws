#!/bin/bash
source ../../vars_init.sh  $(pwd) $1
echo "APPNAME: $APPNAME and TYPE: $TYPE"
echo "====> Remember to create jobs with creates_jobs.sh script before executing this job."
gcloud beta run jobs deploy $TYPE-$APPNAME-job --source=. --region=europe-west1 --max-retries=1 \
--set-env-vars APPNAME=$APPNAME,APP_TYPE=$APP_TYPE \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data \
--execute-now