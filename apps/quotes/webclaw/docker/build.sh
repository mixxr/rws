#!/bin/bash
gcloud beta run jobs deploy quotes-webclaw-job --source=. --execute-now --region=europe-west1 \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data