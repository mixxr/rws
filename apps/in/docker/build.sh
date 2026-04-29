#!/bin/bash
ISIN_LIST="CH1525083577|CH1550421528"
TYPE_LIST="tickers|details|quotes"
ISSUER="leonteq"
BUCKET="gs://rws-data"

APPNAME=$(basename $(dirname $(pwd)))

echo "APP NAME: $APPNAME, ISSUER: $ISSUER, TYPE_LIST: $TYPE_LIST, BUCKET: $BUCKET"
gcloud beta run jobs deploy $APPNAME-params-job --source=. --region=europe-west1 --max-retries=0 \
--set-env-vars ISSUER=$ISSUER,BUCKET=$BUCKET,TYPE_LIST="$TYPE_LIST",ISIN_LIST="$ISIN_LIST" \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data