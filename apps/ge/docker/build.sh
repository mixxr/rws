#!/bin/bash
source ../../vars_init.sh
# test if $1 and $2 are set
if [ -z "$1" ]; then
  echo "Usage: $0 <type[issuer|details|quotes]> [<output_dir>(eg.bq_staging)]"
  exit 1
fi
TYPE=$1
STATUS=2
CMD_NAME="geminicert"
APPNAME=$(basename $(dirname $(pwd)))
OUTPUT_DIR="${2:-$TYPE}"

case "$TYPE" in
  details|issuer|quotes)
    ;;
  *)
    echo "Error: TYPE must be one of: details, issuer, quotes. Got: $TYPE"
    exit 1
    ;;
esac
# source ../../check_input.sh  $1 $2 $3

echo "APP NAME: $APPNAME, STATUS: $STATUS, TYPE: $TYPE, CMD_NAME: $CMD_NAME, OUTPUT_DIR: $OUTPUT_DIR"
echo "====> Remember to create jobs with creates_jobs.sh script before executing this job."
gcloud beta run jobs deploy $TYPE-$APPNAME-s$STATUS-job --source=. --region=europe-west1 \
--set-env-vars STATUS=$STATUS,APP_TYPE=$TYPE,CMD_NAME=$CMD_NAME,OUTPUT_DIR=$OUTPUT_DIR,APPVERSION=$APPVERSION \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data \
--set-secrets=G_API_KEY=projects/600125851897/secrets/gemini-api-key/versions/latest 