#!/bin/bash
source ../../vars_init.sh
# TYPES is an array to be passed as argument. 
TYPES="details|quotes|issuer|tickers|ex_dates"
FOLDERS="bq_staging|quotes|bq_staging|bq_staging|bq_staging"
STATUS=3
CMD_NAME="gs_load"
APPNAME=$(basename $(dirname $(pwd)))
MOUNT_DIR="/data"
MOUNT_BUCKET="gs://rws-data"
TABLE_PREFIX="staging_"

# print all vars pretty multiline as header Configuration
echo "BQ Setup Script - Version 0.2"
echo "==== Setup running... ===="
echo "APP NAME: $APPNAME"   
echo "STATUS: $STATUS"
echo "TYPES: $TYPES"
echo "FOLDERS: $FOLDERS"
echo "CMD_NAME: $CMD_NAME"
echo "MOUNT_DIR: $MOUNT_DIR"
echo "MOUNT_BUCKET: $MOUNT_BUCKET"
echo "TABLE_PREFIX: $TABLE_PREFIX"
echo "APPVERSION: $APPVERSION"

# ask user to confirm before proceeding
read -p "Do you want to proceed with the setup? (y/n) " -n 1 -r
echo    # move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Setup aborted by user."
  exit 1
fi
gcloud beta run jobs deploy $APPNAME-s$STATUS-job --source=. --region=europe-west1 --max-retries=0 \
--set-env-vars STATUS=$STATUS,APP_TYPES="$TYPES",APP_FOLDERS="$FOLDERS",CMD_NAME=$CMD_NAME,TABLE_PREFIX=$TABLE_PREFIX,MOUNT_DIR=$MOUNT_DIR,MOUNT_BUCKET=$MOUNT_BUCKET,APPVERSION=$APPVERSION \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data