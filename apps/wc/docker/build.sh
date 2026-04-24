#!/bin/bash
# test if $1 and $2 are set
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <appname> <cmd_name>[webclaw|curl]"
  exit 1
fi
source ../../vars_init.sh  $(pwd) $1
echo "APPNAME: $APPNAME, TYPE: $TYPE, CMD_NAME: $2"
echo "====> Remember to create jobs with creates_jobs.sh script before executing this job."
gcloud beta run jobs deploy $TYPE-$APPNAME-job --source=. --region=europe-west1 --max-retries=1 \
--set-env-vars APPNAME=$APPNAME,APP_TYPE=$TYPE,CMD_NAME=$2 \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data