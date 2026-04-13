#!/bin/bash
# TODO: obtain jobtype and name from build.sh path (eg. $type="quotes")
TYPE="quotes"
gcloud beta run jobs deploy $TYPE-webclaw-job --source=. --region=europe-west1 \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data \
--execute-now