#!/bin/bash
source ../../vars_init.sh
# TYPES is an array to be passed as argument. 
STATUS=4
CMD_NAME="gs_load"
APPNAME=$(basename $(dirname $(pwd)))
MOUNT_DIR="/data"
MOUNT_BUCKET="gs://rws-data"

# print all vars pretty multiline as header Configuration
echo "BQ Consolidation Setup Script - Version 0.2"
echo "==== Setup running... ===="
echo "APP NAME: $APPNAME"   
echo "STATUS: $STATUS"
echo "MOUNT_DIR: $MOUNT_DIR"
echo "MOUNT_BUCKET: $MOUNT_BUCKET"
echo "APPVERSION: $APPVERSION"

# ask user to confirm before proceeding
read -p "Do you want to proceed with the setup? (y/n) " -n 1 -r
echo    # move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Setup aborted by user."
  exit 1
fi
gcloud beta run jobs deploy $APPNAME-s$STATUS-job --source=. --region=europe-west1 --max-retries=0 \
--set-env-vars MOUNT_DIR=$MOUNT_DIR,MOUNT_BUCKET=$MOUNT_BUCKET,APPVERSION=$APPVERSION \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data