#!/bin/bash
APPNAME=$(basename $(dirname $PWD))
TYPE=$1
# test if TYPE is correctly set
if [ -z "$TYPE" ]; then
  echo "Please provide TYPE (isin, isin_tickers, quotes) as argument. Usage: ./build.sh <TYPE>"
  exit 1
fi
case "$TYPE" in
  isin|isin_tickers|quotes)
    ;;
  *)
    echo "Error: TYPE must be one of: isin, isin_tickers, quotes. Got: $TYPE"
    exit 1
    ;;
esac
echo "APPNAME: $APPNAME and TYPE: $TYPE"
echo "====> Remember to create jobs with creates_jobs.sh script before executing this job."
gcloud beta run jobs deploy $TYPE-$APPNAME-job --source=. --region=europe-west1 --max-retries=1 \
--set-env-vars APPNAME=$APPNAME,APP_TYPE=$APP_TYPE \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data \
--execute-now