#!/bin/bash
source ../../vars_init.sh
# test if $1 and $2 are set
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <type[issuer|details|quotes]> <cmd_name>[webclaw|curl] [<start_next_job[false]>]"
  exit 1
fi
TYPE=$1
STATUS=1
CMD_NAME=$2
START_NEXT_JOB=${3:-false}
APPNAME=$(basename $(dirname $(pwd)))

case "$TYPE" in
  details|issuer|quotes)
    ;;
  *)
    echo "Error: TYPE must be one of: details (it produces details and tickers), issuer, quotes. Got: $TYPE"
    exit 1
    ;;
esac
# source ../../check_input.sh  $1 $2 $3

echo "APP NAME: $APPNAME, STATUS: $STATUS, TYPE: $TYPE, CMD_NAME: $CMD_NAME, START_NEXT_JOB: $START_NEXT_JOB"
echo "====> Remember to create jobs with creates_jobs.sh script before executing this job."
gcloud beta run jobs deploy $TYPE-$APPNAME-s$STATUS-job --source=. --region=europe-west1 --max-retries=1 \
--set-env-vars STATUS=$STATUS,APP_TYPE=$TYPE,CMD_NAME=$CMD_NAME,START_NEXT_JOB=$START_NEXT_JOB,APPVERSION=$APPVERSION \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data