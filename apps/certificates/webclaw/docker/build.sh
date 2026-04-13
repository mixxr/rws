#!/bin/bash
gcloud beta run jobs deploy certs-webclaw-job --source=. --region=europe-west1 \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data \
--execute-now