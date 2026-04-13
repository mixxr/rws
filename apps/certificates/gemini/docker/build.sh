#!/bin/bash
TYPE="certs"
JOB="geminicert"
gcloud beta run jobs deploy $TYPE-$JOB-job --source=. --region=europe-west1 \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data 