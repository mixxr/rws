#!/bin/bash
# TODO: obtain jobtype and name from build.sh path (eg. $type="quotes")
TYPE="certificates"
JOB="webclaw"
gcloud beta run jobs deploy $TYPE-$JOB-job --source=. --region=europe-west1 --max-retries=1 \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data \
--execute-now