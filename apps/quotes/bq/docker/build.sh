#!/bin/bash
source ../../../build_init.sh  $(pwd)
# test if TYPE and APPNAME are correctly set
if [ -z "$TYPE" ] || [ -z "$APPNAME" ]; then
  echo "Error: TYPE or APPNAME is not set."
  exit 1
fi
gcloud beta run jobs deploy $TYPE-$APPNAME-job --source=. --execute-now --region=europe-west1 --max-retries=1 \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data